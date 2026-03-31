import Queue from 'bull';

const downloadQueue = new Queue('download', {
  redis: { host: process.env.REDIS_HOST, port: process.env.REDIS_PORT }
});

export default downloadQueue;