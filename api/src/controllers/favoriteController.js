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

    const userId = req.user.id;

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
          id: fav.id,
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
          id: fav.id,
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
          id: fav.id,
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

    const userId = req.user.id;

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
      return res.status(201).json({ id: favorite.id, track: { id: recording.gid }, created_at: favorite.created_at });
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
      return res.status(201).json({ id: favorite.id, album: { id: album.gid }, created_at: favorite.created_at });
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
      return res.status(201).json({ id: favorite.id, artist: { id: artist.gid }, created_at: favorite.created_at });
    }
  } catch (err) {
    next(err);
  }
};

export const deleteFavorite = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    let favorite = await FavoriteArtist.findOne({ where: { id, user_id: userId } });
    if (!favorite) favorite = await FavoriteAlbum.findOne({ where: { id, user_id: userId } });
    if (!favorite) favorite = await FavoriteTrack.findOne({ where: { id, user_id: userId } });

    if (!favorite) {
      return res.status(404).json({ error: 'Favorite not found' });
    }

    await favorite.destroy();
    res.status(204).send();
  } catch (err) {
    next(err);
  }
};