import express from 'express';
import * as artistController from '../controllers/artistController.js';

const router = express.Router();

router.get('/:mbid', artistController.getArtist);
router.get('/:mbid/albums', artistController.getArtistAlbums);
router.get('/:mbid/tracks', artistController.getArtistTracks);

export default router;