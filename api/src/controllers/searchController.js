import { Op } from 'sequelize';
import { Artist, ReleaseGroup, Recording, ArtistCredit } from '../models/musicbrainz/index.js';

export const search = async (req, res, next) => {
  try {
    const { q, type, limit = 20, offset = 0 } = req.query;

    if (!q) {
      return res.status(400).json({ error: 'Query parameter q required' });
    }

    const parsedLimit = Math.min(Math.max(1, parseInt(limit) || 20), 100);
    const parsedOffset = Math.max(0, parseInt(offset) || 0);

    const searchTerm = `%${q}%`;
    const cleanQuery = q.trim();

    const results = {
      artists: { data: [], total: 0 },
      albums: { data: [], total: 0 },
      tracks: { data: [], total: 0 },
    };

    if (type && !['artist', 'album', 'track'].includes(type)) {
      return res.status(400).json({ error: 'Invalid type parameter' });
    }

    const singleType = type || null;

    const buildWhere = (tableAlias) => ({
      [Op.or]: [
        { [`${tableAlias}.name`]: { [Op.iLike]: searchTerm } },
      ]
    });

    if (!singleType || singleType === 'artist') {
      const { count, rows: artists } = await Artist.findAndCountAll({
        where: { name: { [Op.iLike]: searchTerm } },
        limit: parsedLimit,
        offset: parsedOffset,
        attributes: ['gid', 'name'],
        order: [['name', 'ASC']],
      });
      results.artists = {
        data: artists.map(artist => ({
          id: artist.gid,
          name: artist.name,
        })),
        total: count,
      };
    }

    if (!singleType || singleType === 'album') {
      const { count, rows: albums } = await ReleaseGroup.findAndCountAll({
        where: { name: { [Op.iLike]: searchTerm } },
        limit: parsedLimit,
        offset: parsedOffset,
        include: [{ model: ArtistCredit, as: 'artistCredit', attributes: ['name'] }],
        order: [['name', 'ASC']],
      });
      results.albums = {
        data: albums.map(album => ({
          id: album.gid,
          title: album.name,
          artist: album.artistCredit?.name || null,
        })),
        total: count,
      };
    }

    if (!singleType || singleType === 'track') {
      const { count, rows: tracks } = await Recording.findAndCountAll({
        where: { name: { [Op.iLike]: searchTerm } },
        limit: parsedLimit,
        offset: parsedOffset,
        include: [{ model: ArtistCredit, as: 'artistCredit', attributes: ['name'] }],
        order: [['name', 'ASC']],
      });
      results.tracks = {
        data: tracks.map(track => ({
          id: track.gid,
          title: track.name,
          artist: track.artistCredit?.name || null,
          duration: track.length,
        })),
        total: count,
      };
    }

    res.json(results);
  } catch (err) {
    next(err);
  }
};