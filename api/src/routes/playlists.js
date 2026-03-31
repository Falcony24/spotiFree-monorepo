import express from 'express';
import auth from '../middlewares/auth.js';
import * as playlistController from '../controllers/playlistController.js';

const router = express.Router();

router.use(auth);

router.get('/', playlistController.getMyPlaylists);
router.post('/', playlistController.createPlaylist);
router.get('/:id', playlistController.getPlaylist);
router.put('/:id', playlistController.updatePlaylist);
router.delete('/:id', playlistController.deletePlaylist);

router.post('/:id/tracks', playlistController.addTrack);
router.delete('/:id/tracks/:track_mbid', playlistController.removeTrack);
router.put('/:id/tracks', playlistController.reorderTracks);

export default router;