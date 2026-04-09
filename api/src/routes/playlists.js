import express from 'express';
import auth from '../middlewares/auth.js';
import * as playlistController from '../controllers/playlistController.js';

const router = express.Router();

router.use(auth);

router.get('/', playlistController.getMyPlaylists);
router.post('/', playlistController.createPlaylist);
router.get('/:gid', playlistController.getPlaylist);
router.put('/:gid', playlistController.updatePlaylist);
router.delete('/:gid', playlistController.deletePlaylist);

router.post('/:gid/tracks', playlistController.addTrack);
router.delete('/:gid/tracks/:track_mbid', playlistController.removeTrack);
router.put('/:gid/tracks', playlistController.reorderTracks);

export default router;