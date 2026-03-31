import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

if (process.env.NODE_ENV === 'development' || process.env.NODE_ENV === undefined) {
  dotenv.config({ path: path.resolve(__dirname, '../.env') });
} else if (process.env.NODE_ENV === 'test') {
  dotenv.config({ path: path.resolve(__dirname, '../.env.test') });
}
