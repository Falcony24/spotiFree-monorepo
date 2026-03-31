import express from 'express';
import auth from '../middlewares/auth.js';
import * as albumController from '../controllers/albumController.js';

const router = express.Router();

router.use(auth); 

router.get('/:mbid', albumController.getAlbum);
router.get('/', albumController.getAlbums);
router.get('/:mbid/tracks', albumController.getAlbumTracks);

export default router;