import express from 'express';
import auth from '../middlewares/auth.js';
import * as trackController from '../controllers/trackController.js';

const router = express.Router();

router.use(auth);

router.get('/:mbid/stream', trackController.stream);
router.get('/tasks/:taskId', trackController.getTaskStatus);
router.get('/:mbid/audio', trackController.streamAudio);

export default router;