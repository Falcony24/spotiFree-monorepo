import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const Artist = sequelize.define('Artist', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true
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
  sort_name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  type: DataTypes.INTEGER,
  area: DataTypes.INTEGER,
  gender: DataTypes.INTEGER,
  comment: DataTypes.STRING,
  begin_date_year: DataTypes.SMALLINT,
  begin_date_month: DataTypes.SMALLINT,
  begin_date_day: DataTypes.SMALLINT,
  end_date_year: DataTypes.SMALLINT,
  end_date_month: DataTypes.SMALLINT,
  end_date_day: DataTypes.SMALLINT,
  ended: DataTypes.BOOLEAN
}, {
  tableName: 'artist',
  timestamps: false
});

export default Artist;