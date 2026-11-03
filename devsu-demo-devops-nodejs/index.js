import sequelize from './shared/database/database.js'
import { usersRouter } from "./users/router.js"
import express from 'express'

const app = express()
const PORT = process.env.PORT || 8000
const DATABASE_CHECK_TIMEOUT_MS = Number(process.env.DATABASE_CHECK_TIMEOUT_MS || 1500)

let schemaInitialization = null

const ensureSchema = () => {
    if (schemaInitialization) {
        return schemaInitialization
    }

    const attempt = sequelize.sync()
        .then(() => {
            console.log('db is ready')
        })
        .catch((error) => {
            if (schemaInitialization === attempt) {
                schemaInitialization = null
            }
            throw error
        })

    schemaInitialization = attempt
    return attempt
}

const checkDatabase = async () => {
    await sequelize.authenticate()
    await ensureSchema()
}

const withTimeout = (promise, milliseconds) => new Promise((resolve, reject) => {
    const timer = setTimeout(
        () => reject(new Error(`database check exceeded ${milliseconds}ms`)),
        milliseconds
    )

    promise.then(
        (value) => {
            clearTimeout(timer)
            resolve(value)
        },
        (error) => {
            clearTimeout(timer)
            reject(error)
        }
    )
})

const databaseInitialization = checkDatabase()
    .catch((error) => {
        console.error('database initialization failed', error.message)
    })

app.use(express.json())
app.get('/health', (_request, response) => response.status(200).json({ status: 'ok' }))
app.get('/ready', async (_request, response) => {
    try {
        await withTimeout(checkDatabase(), DATABASE_CHECK_TIMEOUT_MS)
        return response.status(200).json({ status: 'ready' })
    } catch (error) {
        console.error('readiness check failed:', error.message)
        return response.status(503).json({ status: 'not ready' })
    }
})
app.use('/api/users', usersRouter)

const server = app.listen(PORT, () => {
    console.log('Server running on port PORT', PORT)
})

export { app, databaseInitialization, server }
