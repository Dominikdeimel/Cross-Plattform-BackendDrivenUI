const express = require('express')
const fs = require('fs')
const app = express()
const port = 3000
app.get('/screen', async (req, res) => {
    let screenName = req.query.screenName
    try {
        let rawData = await fs.promises.readFile('views/' + screenName + '.json')
        let parsedJson = JSON.parse(rawData.toString())

        res.send(parsedJson)
    } catch (e) {
        console.log(e)
        res.status(500)
        res.send(e)
    }
})


app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
})