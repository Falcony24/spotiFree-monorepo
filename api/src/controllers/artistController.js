import { Artist, ReleaseGroup, Recording, ArtistCredit, ArtistCreditName } from '../models/musicbrainz/index.js';
import { Op } from 'sequelize';
import sequelize from '../config/database.js'; 

const getArtistCreditIds = async (artistId) => {
  const rows = await ArtistCreditName.findAll({
    where: { artist: artistId },
    attributes: [[sequelize.fn('DISTINCT', sequelize.col('artist_credit')), 'artist_credit']],
    raw: true
  });
  return rows.map(row => row.artist_credit);
};

export const getArtist = async (req, res, next) => {
  try {
    const { mbid } = req.params;
    const artist = await Artist.findOne({
      where: { gid: mbid },
      attributes: ['gid', 'name', 'sort_name', 'begin_date_year', 'end_date_year', 'comment']
    });
    if (!artist) return res.status(404).json({ error: 'Artist not found' });
    res.json(artist);
  } catch (err) {
    next(err);
  }
};

export const getArtistAlbums = async (req, res, next) => {
  try {
    const { mbid } = req.params;
    const limit = Math.min(Math.max(1, parseInt(req.query.limit) || 20), 100);
    const offset = Math.max(0, parseInt(req.query.offset) || 0);

    const artist = await Artist.findOne({ where: { gid: mbid } });
    if (!artist) return res.status(404).json({ error: 'Artist not found' });

    const creditIds = await getArtistCreditIds(artist.id);
    if (!creditIds.length) {
      return res.json({ data: [], total: 0, limit, offset });
    }

    const { count, rows: albums } = await ReleaseGroup.findAndCountAll({
      where: { artist_credit: { [Op.in]: creditIds } },
      include: [{ model: ArtistCredit, as: 'artistCredit', attributes: ['name'] }],
      limit,
      offset,
      order: [['name', 'ASC']],
      distinct: true 
    });

    const mapped = albums.map(album => ({
      id: album.gid,
      title: album.name,
      artist: album.artistCredit?.name,
    }));

    res.json({ data: mapped, total: count, limit, offset });
  } catch (err) {
    next(err);
  }
};

export const getArtistTracks = async (req, res, next) => {
  try {
    const { mbid } = req.params;
    const limit = Math.min(Math.max(1, parseInt(req.query.limit) || 20), 100);
    const offset = Math.max(0, parseInt(req.query.offset) || 0);

    const artist = await Artist.findOne({ where: { gid: mbid } });
    if (!artist) return res.status(404).json({ error: 'Artist not found' });

    const creditIds = await getArtistCreditIds(artist.id);
    if (!creditIds.length) {
      return res.json({ data: [], total: 0, limit, offset });
    }

    const total = await Recording.count({
      where: { artist_credit: { [Op.in]: creditIds } },
      distinct: true,
    });

    const tracks = await Recording.findAll({
      where: { artist_credit: { [Op.in]: creditIds } },
      include: [{ model: ArtistCredit, as: 'artistCredit', attributes: ['name'] }],
      limit,
      offset,
      order: [['name', 'ASC']],
      subQuery: false, 
    });

    const mapped = tracks.map(track => ({
      id: track.gid,
      title: track.name,
      artist: track.artistCredit?.name,
      duration: track.length,
    }));

    res.json({ data: mapped, total, limit, offset });
  } catch (err) {
    next(err);
  }
};