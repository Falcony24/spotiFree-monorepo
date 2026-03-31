import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ReleaseMeta = sequelize.define('ReleaseMeta', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  date_added: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  info_url: DataTypes.STRING(255),
  amazon_asin: DataTypes.STRING(10),
  cover_art_presence: {
    type: DataTypes.TEXT,
    defaultValue: 'absent'
  }
}, {
  tableName: 'release_meta',
  timestamps: false
});

export default ReleaseMeta;