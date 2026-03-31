import ytdlp from 'yt-dlp-exec';
import path from 'path';
import fs from 'fs';
import os from 'os';
import { exec } from 'child_process';
import { promisify } from 'util';
import { uploadFile } from '../services/storage/minioClient.js';
import { Recording, ArtistCreditName, Artist } from '../models/musicbrainz/index.js';
import { DownloadTask } from '../models/index.js';

const execAsync = promisify(exec);

export default async function processDownloadJob(job) {
  const { trackMbid, taskId } = job.data;
  let tempFilePath = null;

  try {
    const metadata = await getTrackMetadata(trackMbid);
    const candidates = await findYouTubeCandidates(metadata);
    if (!candidates.length) throw new Error('No YouTube results found');

    let bestResult = null;
    for (const candidate of candidates) {
      try {
        tempFilePath = await downloadFromYouTubeUrl(candidate.url);
        bestResult = candidate;
        break;
      } catch (err) {
        console.warn(`Failed to download ${candidate.title} (${candidate.url}): ${err.message}`);
      }
    }
    if (!bestResult) throw new Error('All YouTube attempts failed');

    console.log(`Downloaded to ${tempFilePath}`);

    const objectKey = `audio/${trackMbid}.mp3`;
    await uploadFile(objectKey, tempFilePath, {
      'Content-Type': 'audio/mpeg',
      'x-amz-meta-title': metadata.title,
      'x-amz-meta-artist': metadata.artist,
      'x-amz-meta-duration': metadata.duration?.toString() || ''
    });

    console.log(`Uploaded to MinIO: ${objectKey}`);

    await DownloadTask.update(
      {
        status: 'completed',
        source_url: objectKey,
        updated_at: new Date()
      },
      { where: { id: taskId } }
    );

    fs.unlinkSync(tempFilePath);
    return { success: true, objectKey };
  } catch (error) {
    console.error('Download job failed:', error);
    if (taskId) {
      await DownloadTask.update(
        {
          status: 'failed',
          retries: job.attemptsMade,
          updated_at: new Date()
        },
        { where: { id: taskId } }
      );
    }
    if (tempFilePath && fs.existsSync(tempFilePath)) {
      fs.unlinkSync(tempFilePath);
    }
    throw error;
  }
}

async function findYouTubeCandidates(metadata) {
  const searchQuery = `${metadata.artist} - ${metadata.title}`;
  console.log(`Searching YouTube for: ${searchQuery}`);

  const command = `yt-dlp -J --flat-playlist "ytsearch30:${searchQuery}" --no-playlist`;
  const { stdout, stderr } = await execAsync(command, { maxBuffer: 10 * 1024 * 1024 });
  if (stderr) console.error('yt-dlp stderr:', stderr);

  const data = JSON.parse(stdout);
  const entries = data.entries || [];
  if (!entries.length) return [];

  const penalizingWords = ['live', 'concert', 'tour', 'performance', 'on stage', 'live at', 'acoustic', 'cover', 'remix', 'instrumental', 'koncert'];
  const rewardingWords = ['official', 'original', 'music video', 'audio', 'studio', 'video'];

  const scored = entries.map(entry => {
    const title = entry.title.toLowerCase();
    const expected = `${metadata.artist} ${metadata.title}`.toLowerCase();
    const expectedWords = new Set(expected.split(/\s+/));
    const titleWords = new Set(title.split(/\s+/));
    const common = [...expectedWords].filter(w => titleWords.has(w)).length;
    const similarity = common / Math.max(expectedWords.size, titleWords.size);

    let durationScore = 1;
    if (metadata.duration && entry.duration) {
      const expectedDurationSec = metadata.duration / 1000;
      const diff = Math.abs(entry.duration - expectedDurationSec);
      durationScore = Math.max(0, 1 - diff / expectedDurationSec);
    }

    let penalty = 0;
    for (const word of penalizingWords) {
      if (title.includes(word)) penalty += 0.15;
    }
    let bonus = 0;
    for (const word of rewardingWords) {
      if (title.includes(word)) bonus += 0.1;
    }
    const totalScore = similarity * 0.6 + durationScore * 0.3 + bonus - penalty;
    console.log(`Candidate: ${entry.title} (duration: ${entry.duration}) -> score: ${totalScore.toFixed(3)}`);
    return { ...entry, totalScore };
  });

  const validCandidates = scored
    .filter(c => c.url && c.url.startsWith('http'))
    .sort((a, b) => b.totalScore - a.totalScore);

  console.log(`Found ${validCandidates.length} candidates, best: ${validCandidates[0]?.title} (score ${validCandidates[0]?.totalScore.toFixed(3)})`);
  return validCandidates;
}

async function downloadFromYouTubeUrl(url) {
  const tmpDir = os.tmpdir();
  const outputTemplate = path.join(tmpDir, '%(title)s.%(ext)s');
  await ytdlp(url, {
    extractAudio: true,
    audioFormat: 'mp3',
    output: outputTemplate,
    noPlaylist: true,
    preferFreeFormats: true,
    'js-runtime': 'node',
  });

  const files = fs.readdirSync(tmpDir);
  const mp3Files = files.filter(f => f.endsWith('.mp3'));
  if (mp3Files.length === 0) throw new Error('No MP3 file generated');
  const latest = mp3Files
    .map(f => ({ name: f, time: fs.statSync(path.join(tmpDir, f)).mtimeMs }))
    .sort((a, b) => b.time - a.time)[0].name;
  return path.join(tmpDir, latest);
}

async function getTrackMetadata(trackMbid) {
  const recording = await Recording.findOne({
    where: { gid: trackMbid },
    include: [
      {
        model: ArtistCreditName,
        as: 'artistCreditNames',
        include: [{ model: Artist, as: 'Artist' }]
      }
    ]
  });
  if (!recording) throw new Error('Recording not found in MusicBrainz');

  const artistNames = recording.artistCreditNames
    .sort((a, b) => a.position - b.position)
    .map(acn => acn.name || acn.artist.name)
    .join(' ');

  return {
    title: recording.name,
    artist: artistNames,
    duration: recording.length
  };
}