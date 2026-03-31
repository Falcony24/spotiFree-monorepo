import downloadQueue from './queues/downloadQueue.js';
import processDownloadJob from './jobs/processDownload.js';
import { initBucket } from './services/storage/minioClient.js';

console.log('Worker starting...');

initBucket()
  .then(() => console.log('MinIO bucket ready'))
  .catch(err => {
    console.error('Failed to initialize MinIO bucket:', err);
    process.exit(1);
  });

downloadQueue.process(processDownloadJob);

downloadQueue.on('completed', (job, result) => {
  console.log(`Job ${job.id} completed, result:`, result);
});

downloadQueue.on('failed', (job, err) => {
  console.error(`Job ${job.id} failed:`, err);
});

console.log('Worker started, waiting for jobs...');
setInterval(() => {}, 1000);