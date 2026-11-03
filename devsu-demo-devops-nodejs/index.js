import sequelize from './shared/database/database.js'
import { usersRouter } from "./users/router.js"
import express from 'express'

const app = express()
const PORT = process.env.PORT || 8000
let databaseReady = false

const databaseInitialization = sequelize.authenticate()
  .then(() => sequelize.sync())
  .then(() => {
    databaseReady = true
    console.log('db is ready')
  })
  .catch((error) => {
    console.error('database initialization failed', error)
  })

app.use(express.json())
app.get('/health', (_request, response) => response.status(200).json({ status: 'ok' }))
app.get('/ready', (_request, response) => {
    if (!databaseReady) {
        return response.status(503).json({ status: 'not ready' })
    }

    return response.status(200).json({ status: 'ready' })
})
app.use('/api/users', usersRouter)

const server = app.listen(PORT, () => {
    console.log('Server running on port PORT', PORT)
})

export { app, databaseInitialization, server }
