import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const Release = sequelize.define('Release', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  gid: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  artist_credit: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  release_group: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  status: DataTypes.INTEGER,
  packaging: DataTypes.INTEGER,
  language: DataTypes.INTEGER,
  script: DataTypes.INTEGER,
  barcode: DataTypes.STRING(255),
  comment: {
    type: DataTypes.STRING(255),
    defaultValue: ''
  },
  edits_pending: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  quality: {
    type: DataTypes.SMALLINT,
    defaultValue: -1
  },
  last_updated: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'release',
  timestamps: false,
  indexes: [
    { fields: ['gid'] },
    { fields: ['name'] },
    { fields: ['artist_credit'] },
    { fields: ['release_group'] }
  ]
});

export default Release;