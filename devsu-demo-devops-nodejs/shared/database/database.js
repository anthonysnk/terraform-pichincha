import * as dotenv from 'dotenv'
import { Sequelize } from 'sequelize'

dotenv.config()

const dialect = process.env.DATABASE_DIALECT || 'sqlite'
const databaseName = process.env.DATABASE_NAME || 'dev.sqlite'

const sequelizeOptions = dialect === 'sqlite'
  ? {
      dialect,
      storage: databaseName
    }
  : {
      dialect,
      host: process.env.DATABASE_HOST || '127.0.0.1',
      port: Number(process.env.DATABASE_PORT || 5432),
      logging: false
    }

const sequelize = new Sequelize(
  databaseName,
  process.env.DATABASE_USER,
  process.env.DATABASE_PASSWORD,
  sequelizeOptions
)

export default sequelize
