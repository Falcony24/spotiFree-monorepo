import { Op } from 'sequelize';
import { Playlist, PlaylistTrack } from '../models/index.js';
import { Recording, ArtistCredit } from '../models/musicbrainz/index.js'; 
import sequelize from '../config/database.js';

export const getMyPlaylists = async (req, res, next) => {
  try {
    const limit = Math.min(Math.max(1, parseInt(req.query.limit) || 20), 100);
    const offset = Math.max(0, parseInt(req.query.offset) || 0);

    const { count, rows: playlists } = await Playlist.findAndCountAll({
      where: { user_id: req.user.id },
      order: [['created_at', 'DESC']],
      limit,
      offset,
    });

    res.json({
      data: playlists,
      total: count,
      limit,
      offset,
    });
  } catch (err) {
    next(err);
  }
};

export const createPlaylist = async (req, res, next) => {
  try {
    const { name, description, is_public } = req.body;
    const playlist = await Playlist.create({
      user_id: req.user.id,
      name,
      description,
      is_public: is_public ?? false,
    });
    res.status(201).json(playlist);
  } catch (err) {
    next(err);
  }
};

export const getPlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findByPk(req.params.id);
    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }
    if (playlist.user_id !== req.user.id && !playlist.is_public) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const playlistTracks = await PlaylistTrack.findAll({
      where: { playlist_id: playlist.id },
      order: [['position', 'ASC']],
    });

    if (playlistTracks.length === 0) {
      return res.json({ playlist, tracks: [] });
    }

    const mbids = playlistTracks.map(pt => pt.track_mbid);
    const recordings = await Recording.findAll({
      where: { gid: { [Op.in]: mbids } },
      include: [
        {
          model: ArtistCredit,
          as: 'artistCredit',
          attributes: ['name'],
        },
      ],
    });

    const recordingMap = {};
    recordings.forEach(rec => {
      recordingMap[rec.gid] = rec;
    });

    const tracks = playlistTracks.map(pt => {
      const rec = recordingMap[pt.track_mbid];
      return {
        id: pt.id,
        track_mbid: pt.track_mbid,
        position: pt.position,
        added_at: pt.created_at,
        track: rec
          ? {
              id: rec.gid,
              title: rec.name,
              artist: rec.artistCredit?.name || 'Unknown',
              duration: rec.length,
            }
          : null, 
      };
    });

    res.json({ playlist, tracks });
  } catch (err) {
    next(err);
  }
};

export const updatePlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findByPk(req.params.id);
    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }
    if (playlist.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const { name, description, is_public } = req.body;
    await playlist.update({ name, description, is_public });
    res.json(playlist);
  } catch (err) {
    next(err);
  }
};

export const deletePlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findByPk(req.params.id);
    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }
    if (playlist.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    await playlist.destroy();
    res.status(204).send();
  } catch (err) {
    next(err);
  }
};

export const addTrack = async (req, res, next) => {
  const t = await sequelize.transaction();
  try {
    const playlist = await Playlist.findByPk(req.params.id, { transaction: t });
    if (!playlist || playlist.user_id !== req.user.id) {
      await t.rollback();
      return res.status(403).json({ error: 'Forbidden' });
    }

    const { track_mbid, position } = req.body;

    const recording = await Recording.findOne({
      where: { gid: track_mbid },
      transaction: t,
    });
    if (!recording) {
      await t.rollback();
      return res.status(404).json({ error: 'Track not found in MusicBrainz' });
    }

    let pos = position;
    if (pos === undefined) {
      const maxPos = await PlaylistTrack.max('position', {
        where: { playlist_id: playlist.id },
        transaction: t,
      });
      pos = (maxPos || 0) + 1;
    } else {
      await PlaylistTrack.increment('position', {
        by: 1,
        where: {
          playlist_id: playlist.id,
          position: { [Op.gte]: pos },
        },
        transaction: t,
      });
    }

    const track = await PlaylistTrack.create(
      {
        playlist_id: playlist.id,
        track_mbid,
        position: pos,
      },
      { transaction: t }
    );

    await t.commit();
    res.status(201).json(track);
  } catch (err) {
    await t.rollback();
    next(err);
  }
};

export const removeTrack = async (req, res, next) => {
  const t = await sequelize.transaction();
  try {
    const playlist = await Playlist.findByPk(req.params.id, { transaction: t });
    if (!playlist || playlist.user_id !== req.user.id) {
      await t.rollback();
      return res.status(403).json({ error: 'Forbidden' });
    }

    const track = await PlaylistTrack.findOne({
      where: {
        playlist_id: playlist.id,
        track_mbid: req.params.track_mbid,
      },
      transaction: t,
    });
    if (!track) {
      await t.rollback();
      return res.status(404).json({ error: 'Track not in playlist' });
    }

    await track.destroy({ transaction: t });

    await PlaylistTrack.decrement('position', {
      by: 1,
      where: {
        playlist_id: playlist.id,
        position: { [Op.gt]: track.position },
      },
      transaction: t,
    });

    await t.commit();
    res.status(204).send();
  } catch (err) {
    await t.rollback();
    next(err);
  }
};

export const reorderTracks = async (req, res, next) => {
  const t = await sequelize.transaction();
  try {
    const playlist = await Playlist.findByPk(req.params.id, { transaction: t });
    if (!playlist || playlist.user_id !== req.user.id) {
      await t.rollback();
      return res.status(403).json({ error: 'Forbidden' });
    }

    const newOrder = req.body;
    if (!Array.isArray(newOrder) || !newOrder.every(item => item.track_mbid && typeof item.position === 'number')) {
      await t.rollback();
      return res.status(400).json({ error: 'Invalid data, expected array of { track_mbid, position }' });
    }

    const mbids = newOrder.map(item => item.track_mbid);
    const existing = await Recording.findAll({
      where: { gid: { [Op.in]: mbids } },
      attributes: ['gid'],
      transaction: t,
    });
    if (existing.length !== mbids.length) {
      await t.rollback();
      return res.status(400).json({ error: 'One or more tracks do not exist' });
    }

    await PlaylistTrack.destroy({
      where: { playlist_id: playlist.id },
      transaction: t,
    });

    const tracksToInsert = newOrder.map((item, index) => ({
      playlist_id: playlist.id,
      track_mbid: item.track_mbid,
      position: item.position !== undefined ? item.position : index + 1,
    }));
    await PlaylistTrack.bulkCreate(tracksToInsert, { transaction: t });

    await t.commit();
    res.status(200).json({ message: 'Playlist reordered successfully' });
  } catch (err) {
    await t.rollback();
    next(err);
  }
};