import { Recording } from '../models/musicbrainz/index.js';
import { DownloadTask } from '../models/index.js';
import { getPresignedUrl, getObjectStream, getObjectMetadata } from '../services/storage/minioClient.js';
import downloadQueue from '../queues/downloadQueue.js';
import mime from 'mime-types'; 
import sequelize from '../config/database.js';

async function getOrCreateTask(trackMbid) {
  const transaction = await sequelize.transaction();
  try {
    let task = await DownloadTask.findOne({
      where: { track_mbid: trackMbid },
      transaction,
      lock: true,
    });
    if (!task) {
      task = await DownloadTask.create(
        { track_mbid: trackMbid, status: 'pending' },
        { transaction }
      );
      await transaction.commit();
      await downloadQueue.add({ trackMbid: trackMbid, taskId: task.id });
    } else {
      await transaction.commit();
    }
    return task;
  } catch (err) {
    await transaction.rollback();
    throw err;
  }
}

export const stream = async (req, res, next) => {
  try {
    const { mbid } = req.params;
    const recording = await Recording.findOne({ where: { gid: mbid } });
    if (!recording) return res.status(404).json({ error: 'Track not found' });
    const task = await getOrCreateTask(mbid);
    if (task.status !== 'completed' || !task.source_url) {
      return res.status(202).json({ taskId: task.id, status: task.status });
    }
    const url = await getPresignedUrl(task.source_url);
    res.json({ streamUrl: url });
  } catch (err) {
    next(err);
  }
};

export const streamAudio = async (req, res, next) => {
  try {
    const { mbid } = req.params;

    const task = await getOrCreateTask(mbid);

    if (task.status === 'completed' && task.source_url) {
      const meta = await getObjectMetadata(task.source_url);
      const contentType = meta?.contentType || mime.lookup(task.source_url) || 'audio/mpeg';

      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Disposition', `inline; filename="${mbid}.${meta?.ext || 'mp3'}"`);

      const stream = await getObjectStream(task.source_url, req.headers.range);
      stream.pipe(res);
      stream.on('error', (err) => {
        console.error('Stream error:', err);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Stream error' });
        }
        if (err.code === 'NoSuchKey') {
          task.update({ status: 'failed' }).catch(console.error);
        }
      });
    } else if (task.status === 'pending' || task.status === 'processing') {
      return res.status(202).json({ taskId: task.id, status: task.status });
    } else {
      return res.status(404).json({ error: 'Audio not available' });
    }
  } catch (err) {
    next(err);
  }
};

export const getTaskStatus = async (req, res, next) => {
  try {
    const task = await DownloadTask.findByPk(req.params.taskId);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const result = {
      taskId: task.id,
      status: task.status,
      source_url: task.source_url, 
    };

    if (task.status === 'completed' && task.source_url) {
      result.streamUrl = await getPresignedUrl(task.source_url, 15 * 60);
    }

    res.json(result);
  } catch (err) {
    next(err);
  }
};