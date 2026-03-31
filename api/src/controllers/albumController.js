import sequelize from '../config/database.js';
import { ReleaseGroup, Release, Medium, Track, Recording, ArtistCredit, ArtistCreditName, Artist } from '../models/musicbrainz/index.js';
import { Op } from 'sequelize';

export const getAlbum = async (req, res, next) => {
  try {
    const { mbid } = req.params;
    const album = await ReleaseGroup.findOne({
      where: { gid: mbid },
      attributes: ['gid', 'name', 'type'],
      subQuery: false, 
      include: [
        {
          model: ArtistCredit,
          as: 'artistCredit',
          attributes: ['id'],
          include: [
            {
              model: ArtistCreditName,
              as: 'artistCreditNames',
              attributes: ['artist_credit'],
              include: [
                {
                  model: Artist,
                  as: 'Artist',  
                  attributes: ['gid', 'name']
                }
              ]
            }
          ]
        }
      ]
    });

    if (!album) return res.status(404).json({ error: 'Album not found' });

    res.json({
      id: album.gid,
      title: album.name,
      type: album.type,
      artists: album.artistCredit?.artistCreditNames?.map(acn => acn.Artist?.name) ?? [],
      artistMbids: album.artistCredit?.artistCreditNames?.map(acn => acn.Artist?.gid) ?? []
    });
  } catch (err) {
    next(err);
  }
};

export const getAlbums = async (req, res, next) => {
  try {
    let limit = parseInt(req.query.limit) || 20;
    let offset = parseInt(req.query.offset) || 0;

    limit = Math.min(Math.max(1, limit), 100);
    offset = Math.max(0, offset);

    const order = req.query.order === 'desc' ? 'DESC' : 'ASC';

    const { count, rows: albums } = await ReleaseGroup.findAndCountAll({
      limit,
      offset,
      order: [['name', order]],
      attributes: ['gid', 'name', 'type'],
      subQuery: false, 
      include: [
        {
          model: ArtistCredit,
          as: 'artistCredit',
          attributes: ['id'],
          include: [
            {
              model: ArtistCreditName,
              as: 'artistCreditNames',
              attributes: ['artist_credit'],
              include: [
                {
                  model: Artist,
                  as: 'Artist',
                  attributes: ['gid', 'name']
                }
              ]
            }
          ]
        }
      ]
    });

    const mapped = albums.map(album => ({
      id: album.gid,
      title: album.name,
      type: album.type,
      artists: album.artistCredit?.artistCreditNames?.map(acn => acn.Artist?.name) ?? [],
      artistMbids: album.artistCredit?.artistCreditNames?.map(acn => acn.Artist?.gid) ?? []
    }));

    res.json({ data: mapped, total: count, limit, offset });
  } catch (err) {
    next(err);
  }
};

export const getAlbumTracks = async (req, res, next) => {
  try {
    const { mbid } = req.params;

    const album = await ReleaseGroup.findOne({ where: { gid: mbid } });
    if (!album) return res.status(404).json({ error: 'Album not found' });

    const releases = await Release.findAll({
      where: { release_group: album.id },
      order: [['name', 'ASC']]
    });

    if (!releases.length) return res.json([]);

    const primaryRelease = releases[0];

    const mediums = await Medium.findAll({
      where: { release: primaryRelease.id },
      order: [['position', 'ASC']]
    });

    const mediumIds = mediums.map(m => m.id);

    const tracks = await Track.findAll({
      where: { medium: { [Op.in]: mediumIds } },
      include: [
        {
          model: Recording,
          as: 'recordingDetail',
          include: [
            {
              model: ArtistCredit,
              as: 'artistCredit',
              attributes: ['name']
            }
          ]
        }
      ],
      order: [['position', 'ASC']]
    });

    const mapped = tracks.map(track => {
      const recording = track.recordingDetail;
      return {
        id: recording.gid,
        title: track.name,
        artist: recording?.artistCredit?.name || 'Unknown',
        duration: recording?.length,
      };
    });
    res.json(mapped);
  } catch (err) {
    next(err);
  }
};