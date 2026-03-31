import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const Tag = sequelize.define('Tag', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true
  },
  ref_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  }
}, {
  tableName: 'tag',
  timestamps: false
});

export default Tag;