import { Op } from 'sequelize';
import FavoriteArtist from '../models/FavoriteArtist.js';
import FavoriteAlbum from '../models/FavoriteAlbum.js';
import FavoriteTrack from '../models/FavoriteTrack.js';
import { Recording, ArtistCredit, ReleaseGroup, Artist } from '../models/musicbrainz/index.js';

export const getFavorites = async (req, res, next) => {
  try {
    const { type } = req.query;
    if (!type || !['track', 'artist', 'album'].includes(type)) {
      return res.status(400).json({ error: 'Invalid or missing type parameter' });
    }

    const userId = req.userId;

    if (type === 'track') {
      const favorites = await FavoriteTrack.findAll({
        where: { user_id: userId },
        order: [['created_at', 'DESC']]
      });
      if (favorites.length === 0) return res.json([]);

      const trackIds = favorites.map(f => f.track_id);
      const recordings = await Recording.findAll({
        where: { id: { [Op.in]: trackIds } },
        include: [{ model: ArtistCredit, as: 'artistCredit' }]
      });
      const recordingMap = {};
      recordings.forEach(rec => { recordingMap[rec.id] = rec; });

      const result = favorites.map(fav => {
        const rec = recordingMap[fav.track_id];
        if (!rec) return null;
        return {
          id: fav.gid,
          track: {
            id: rec.gid,
            title: rec.name,
            artist: rec.artistCredit?.name || 'Unknown',
            duration: rec.length
          },
          created_at: fav.created_at
        };
      }).filter(item => item !== null);
      return res.json(result);
    }

    if (type === 'album') {
      const favorites = await FavoriteAlbum.findAll({
        where: { user_id: userId },
        order: [['created_at', 'DESC']]
      });
      if (favorites.length === 0) return res.json([]);

      const albumIds = favorites.map(f => f.album_id);
      const albums = await ReleaseGroup.findAll({
        where: { id: { [Op.in]: albumIds } },
        include: [{ model: ArtistCredit, as: 'artistCredit' }]
      });
      const albumMap = {};
      albums.forEach(album => { albumMap[album.id] = album; });

      const result = favorites.map(fav => {
        const album = albumMap[fav.album_id];
        if (!album) return null;
        return {
          id: fav.gid,
          album: {
            id: album.gid,
            title: album.name,
            artist: album.artistCredit?.name || null,
          },
          created_at: fav.created_at
        };
      }).filter(item => item !== null);
      return res.json(result);
    }

    if (type === 'artist') {
      const favorites = await FavoriteArtist.findAll({
        where: { user_id: userId },
        order: [['created_at', 'DESC']]
      });
      if (favorites.length === 0) return res.json([]);

      const artistIds = favorites.map(f => f.artist_id);
      const artists = await Artist.findAll({
        where: { id: { [Op.in]: artistIds } }
      });
      const artistMap = {};
      artists.forEach(artist => { artistMap[artist.id] = artist; });

      const result = favorites.map(fav => {
        const artist = artistMap[fav.artist_id];
        if (!artist) return null;
        return {
          id: fav.gid,
          artist: {
            id: artist.gid,
            name: artist.name,
          },
          created_at: fav.created_at
        };
      }).filter(item => item !== null);
      return res.json(result);
    }

    res.json([]);
  } catch (err) {
    next(err);
  }
};

export const addFavorite = async (req, res, next) => {
  try {
    const { item_type, item_mbid } = req.body;
    if (!['track', 'artist', 'album'].includes(item_type)) {
      return res.status(400).json({ error: 'Invalid item_type' });
    }

    const userId = req.userId;

    if (item_type === 'track') {
      const recording = await Recording.findOne({ where: { gid: item_mbid } });
      if (!recording) return res.status(404).json({ error: 'Track not found' });

      const [favorite, created] = await FavoriteTrack.findOrCreate({
        where: { user_id: userId, track_id: recording.id },
        defaults: { user_id: userId, track_id: recording.id }
      });
      if (!created) {
        return res.status(409).json({ error: 'Already favorite' });
      }
      return res.status(201).json({ id: favorite.gid, track: { id: recording.gid }, created_at: favorite.created_at });
    }

    if (item_type === 'album') {
      const album = await ReleaseGroup.findOne({ where: { gid: item_mbid } });
      if (!album) return res.status(404).json({ error: 'Album not found' });

      const [favorite, created] = await FavoriteAlbum.findOrCreate({
        where: { user_id: userId, album_id: album.id },
        defaults: { user_id: userId, album_id: album.id }
      });
      if (!created) {
        return res.status(409).json({ error: 'Already favorite' });
      }
      return res.status(201).json({ id: favorite.gid, album: { id: album.gid }, created_at: favorite.created_at });
    }

    if (item_type === 'artist') {
      const artist = await Artist.findOne({ where: { gid: item_mbid } });
      if (!artist) return res.status(404).json({ error: 'Artist not found' });

      const [favorite, created] = await FavoriteArtist.findOrCreate({
        where: { user_id: userId, artist_id: artist.id },
        defaults: { user_id: userId, artist_id: artist.id }
      });
      if (!created) {
        return res.status(409).json({ error: 'Already favorite' });
      }
      return res.status(201).json({ id: favorite.gid, artist: { id: artist.gid }, created_at: favorite.created_at });
    }
  } catch (err) {
    next(err);
  }
};

export const deleteFavorite = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const { type } = req.query;

    let deletedCount = 0;

    switch (type) {
      case 'track':
        deletedCount = await FavoriteTrack.destroy({ where: { gid: id, user_id: userId } });
        break;
      case 'album':
        deletedCount = await FavoriteAlbum.destroy({ where: { gid: id, user_id: userId } });
        break;
      case 'artist':
        deletedCount = await FavoriteArtist.destroy({ where: { gid: id, user_id: userId } });
        break;
      default:
        return res.status(400).json({ error: 'Invalid type' });
    }

    if (deletedCount === 0) {
      return res.status(404).json({ error: 'Favorite not found' });
    }

    res.status(204).send();
  } catch (err) {
    next(err);
  }
};