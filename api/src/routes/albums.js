import express from 'express';
import * as albumController from '../controllers/albumController.js';

const router = express.Router();

router.get('/:mbid', albumController.getAlbum);
router.get('/', albumController.getAlbums);
router.get('/:mbid/tracks', albumController.getAlbumTracks);

export default router;