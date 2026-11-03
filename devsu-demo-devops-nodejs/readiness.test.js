process.env.PORT = '0'

import request from 'supertest'

describe('Readiness under overlapping probes', () => {
    let server

    afterAll(() => {
        if (server) {
            server.close()
        }
    })

    test('runs the schema initialization only once', async () => {
        jest.spyOn(console, 'log').mockImplementation(() => {})
        jest.spyOn(console, 'error').mockImplementation(() => {})

        const sequelize = (await import('./shared/database/database.js')).default
        const sync = jest.fn(() => new Promise((resolve) => setTimeout(resolve, 100)))

        sequelize.authenticate = jest.fn(async () => {})
        sequelize.sync = sync

        const index = await import('./index.js')
        server = index.server

        // The probes arrive while the initialization started at import time is
        // still running, which is what a slow first boot or a late database looks
        // like. Awaiting it first would hide the duplicate work.
        const responses = await Promise.all(
            [1, 2, 3, 4, 5].map(() => request(index.app).get('/ready'))
        )

        expect(responses.map((response) => response.status)).toEqual([200, 200, 200, 200, 200])
        expect(sync).toHaveBeenCalledTimes(1)
    })
})
