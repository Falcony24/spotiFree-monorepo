import express from 'express';
import auth from '../middlewares/auth.js';
import * as artistController from '../controllers/artistController.js';

const router = express.Router();

router.use(auth);

router.get('/:mbid', artistController.getArtist);
router.get('/:mbid/albums', artistController.getArtistAlbums);
router.get('/:mbid/tracks', artistController.getArtistTracks);

export default router;