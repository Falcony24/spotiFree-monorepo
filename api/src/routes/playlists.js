import express from 'express';
import auth from '../middlewares/auth.js';
import * as playlistController from '../controllers/playlistController.js';
import rateLimit from 'express-rate-limit';

const router = express.Router();

const mutateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, 
  max: 30,                  
  keyGenerator: (req) => req.userId, 
  standardHeaders: true,
});

router.use(auth);

router.post('/', mutateLimiter, playlistController.createPlaylist);
router.put('/:gid', mutateLimiter, playlistController.updatePlaylist);
router.delete('/:gid', mutateLimiter, playlistController.deletePlaylist);
router.post('/:gid/tracks', mutateLimiter, playlistController.addTrack);
router.delete('/:gid/tracks/:track_mbid', mutateLimiter, playlistController.removeTrack);
router.put('/:gid/tracks', mutateLimiter, playlistController.reorderTracks);

router.get('/', playlistController.getMyPlaylists);
router.get('/:gid', playlistController.getPlaylist);

export default router;