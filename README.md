Fusion
===

[Fusion](https://github.com/artsy/fusion) is an orchestration layer that does fancy caching/aggregation stuff on top of Artsy's API.

Meta
---

* __State:__ production
* __Production:__ [https://www.artsy.net/](https://www.artsy.net/) | [Heroku](https://dashboard.heroku.com/apps/fusion-production/resources)
* __Staging:__ [https://staging.artsy.net/](https://staging.artsy.net/) | [Heroku](https://dashboard.heroku.com/apps/fusion-staging/resources)
* __Github:__ [https://github.com/artsy/fusion/](https://github.com/artsy/fusion/)
* __CI:__ [Semaphore](https://semaphoreapp.com/artsy/fusion/); merged PRs to artsy/fusion#master are automatically deployed to staging; production is manually deployed from semaphore
* __Point People:__ [@craigspaeth](https://github.com/craigspaeth), [@dzucconi](https://github.com/dzucconi), [@broskoski](https://github.com/broskoski), [@kanaabe](https://github.com/kanaabe)

[![Build Status](https://semaphoreci.com/api/v1/projects/260f0d9d-ddb4-4cc5-b54e-619b98fd9d81/382381/badge.svg)](https://semaphoreci.com/artsy/fusion--2)

Set-Up
---

- Install [NVM](https://github.com/creationix/nvm)
- Install Node 0.12
```
nvm install 0.12
nvm alias default 0.12
```
- Fork Fusion to your Github account in the Github UI.
- Clone your repo locally (substitute your Github username).
```
git clone git@github.com:craigspaeth/fusion.git && cd fusion
```
- Install node modules
```
npm install
```
- Create a .env file and copy in the contents of .env.example
- Replace any `REPLACE` values from staging using `heroku run config --app=fusion-staging`
- Start Fusion
```
foreman start
```
- Fusion should now be running at [http://localhost:5000/](http://localhost:5000/)
