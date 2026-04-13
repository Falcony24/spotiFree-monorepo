import { Op } from 'sequelize';
import { Playlist, PlaylistTrack } from '../models/index.js';
import { Recording, ArtistCredit } from '../models/musicbrainz/index.js';
import sequelize from '../config/database.js';

export const getMyPlaylists = async (req, res, next) => {
  try {
    const limit = Math.min(Math.max(1, parseInt(req.query.limit) || 20), 100);
    const offset = Math.max(0, parseInt(req.query.offset) || 0);

    const { count, rows: playlists } = await Playlist.findAndCountAll({
      where: { user_id: req.userId },
      order: [['created_at', 'DESC']],
      limit,
      offset,
    });

    res.json({
      data: playlists.map(p => ({
        id: p.gid,
        name: p.name,
        description: p.description,
        is_public: p.is_public,
        created_at: p.created_at,
        updated_at: p.updated_at
      })),
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
      user_id: req.userId,
      name,
      description,
      is_public: is_public ?? false,
    });
    res.status(201).json({
      id: playlist.gid,
      name: playlist.name,
      description: playlist.description,
      is_public: playlist.is_public,
      created_at: playlist.created_at,
      updated_at: playlist.updated_at
    });
  } catch (err) {
    next(err);
  }
};

export const getPlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findOne({ where: { gid: req.params.gid } });
    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }
    if (playlist.user_id !== req.userId && !playlist.is_public) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const playlistTracks = await PlaylistTrack.findAll({
      where: { playlist_id: playlist.id },
      order: [['position', 'ASC']],
    });

    if (playlistTracks.length === 0) {
      return res.json({
        playlist: {
          id: playlist.gid,
          name: playlist.name,
          description: playlist.description,
          is_public: playlist.is_public,
          user_id: playlist.user_id,
          created_at: playlist.created_at,
          updated_at: playlist.updated_at
        },
        tracks: []
      });
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

    const tracks = playlistTracks.map(pt => ({
      id: pt.gid,
      track_mbid: pt.track_mbid,
      position: pt.position,
      added_at: pt.created_at,
      track: recordingMap[pt.track_mbid]
        ? {
            id: recordingMap[pt.track_mbid].gid,
            title: recordingMap[pt.track_mbid].name,
            artist: recordingMap[pt.track_mbid].artistCredit?.name || 'Unknown',
            duration: recordingMap[pt.track_mbid].length,
          }
        : null,
    }));

    res.json({
      playlist: {
        id: playlist.gid,
        name: playlist.name,
        description: playlist.description,
        is_public: playlist.is_public,
        user_id: playlist.user_id,
        created_at: playlist.created_at,
        updated_at: playlist.updated_at
      },
      tracks
    });
  } catch (err) {
    next(err);
  }
};

export const updatePlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findOne({ where: { gid: req.params.gid } });
    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }
    if (playlist.user_id !== req.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const { name, description, is_public } = req.body;
    await playlist.update({ name, description, is_public });
    res.json({
      id: playlist.gid,
      name: playlist.name,
      description: playlist.description,
      is_public: playlist.is_public,
      updated_at: playlist.updated_at
    });
  } catch (err) {
    next(err);
  }
};

export const deletePlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findOne({ where: { gid: req.params.gid } });
    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }
    if (playlist.user_id !== req.userId) {
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
    const playlist = await Playlist.findOne({ where: { gid: req.params.gid }, transaction: t });
    if (!playlist || playlist.user_id !== req.userId) {
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
    res.status(201).json({
      id: track.gid,
      playlist_id: playlist.gid,
      track_mbid,
      position: pos,
      added_at: track.created_at
    });
  } catch (err) {
    await t.rollback();
    next(err);
  }
};

export const removeTrack = async (req, res, next) => {
  const t = await sequelize.transaction();
  try {
    const playlist = await Playlist.findOne({ where: { gid: req.params.gid }, transaction: t });
    if (!playlist || playlist.user_id !== req.userId) {
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
    const playlist = await Playlist.findOne({ where: { gid: req.params.gid }, transaction: t });
    if (!playlist || playlist.user_id !== req.userId) {
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
    const createdTracks = await PlaylistTrack.bulkCreate(tracksToInsert, { transaction: t, returning: true });

    await t.commit();
    res.status(200).json({
      message: 'Playlist reordered successfully',
      tracks: createdTracks.map(t => ({
        id: t.gid,
        track_mbid: t.track_mbid,
        position: t.position
      }))
    });
  } catch (err) {
    await t.rollback();
    next(err);
  }
};