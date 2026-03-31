import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const RecordingTag = sequelize.define('RecordingTag', {
  recording: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  tag: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  count: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  last_updated: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'recording_tag',
  timestamps: false,
  indexes: [
    { fields: ['tag'] }
  ]
});

export default RecordingTag;