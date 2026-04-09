import { Client } from 'minio';
import { createReadStream } from 'fs';
import { Readable } from 'stream';

export const internalMinioClient = new Client({
  endPoint: process.env.MINIO_ENDPOINT || 'minio',
  port: parseInt(process.env.MINIO_PORT) || 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin',
  region: 'us-east-1',
});

const publicMinioClient = new Client({
  endPoint: process.env.MINIO_PUBLIC_ENDPOINT || 'localhost',
  port: parseInt(process.env.MINIO_PUBLIC_PORT) || 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin',
  region: 'us-east-1',
});

const BUCKET_NAME = process.env.MINIO_BUCKET || 'audio';

export const initBucket = async () => {
  const exists = await internalMinioClient.bucketExists(BUCKET_NAME);
  if (!exists) {
    await internalMinioClient.makeBucket(BUCKET_NAME);
    console.log(`Bucket '${BUCKET_NAME}' created`);
  }
};

export const getPresignedUrl = async (objectKey, expires = 24 * 60 * 60) => {
  return await publicMinioClient.presignedGetObject(BUCKET_NAME, objectKey, expires);
};

export const uploadFile = async (objectKey, filePath, metadata = {}) => {
  const fileStream = createReadStream(filePath);
  return await internalMinioClient.putObject(BUCKET_NAME, objectKey, fileStream, null, metadata);
};

export const uploadBuffer = async (objectKey, buffer, metadata = {}) => {
  const stream = Readable.from(buffer);
  return await internalMinioClient.putObject(BUCKET_NAME, objectKey, stream, buffer.length, metadata);
};

export const getObjectMetadata = async (objectKey) => {
  const stat = await internalMinioClient.statObject(BUCKET_NAME, objectKey);
  
  const decodeHeader = (val) => {
    if (!val) return val;
    try {
      return decodeURIComponent(val);
    } catch {
      return val; 
    }
  };
  
  return {
    contentType: stat.metaData?.['content-type'],
    ext: objectKey.split('.').pop(),
    size: stat.size,
    title: decodeHeader(stat.metaData?.['title']),
    artist: decodeHeader(stat.metaData?.['artist']),
    duration: stat.metaData?.['duration'],
  };
};

export const getObjectStream = async (objectKey, rangeHeader) => {
  const options = {};
  if (rangeHeader) {
    const range = parseRange(rangeHeader);
    if (range) {
      options.start = range.start;
      options.end = range.end;
    }
  }
  return internalMinioClient.getObject(BUCKET_NAME, objectKey, options);
};

function parseRange(header) {
  const match = header.match(/bytes=(\d+)-(\d*)/);
  if (!match) return null;
  const start = parseInt(match[1], 10);
  const end = match[2] ? parseInt(match[2], 10) : undefined;
  return { start, end };
}

export default internalMinioClient;