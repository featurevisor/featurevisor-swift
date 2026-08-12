import Foundation

extension FeaturevisorInstance {

    // MARK: - Refresh

    public func refresh() {
        logger.debug("refreshing datafile")

        if statuses.refreshInProgress {
            logger.warn("refresh in progress, skipping")
            return
        }

        guard let datafileUrl else {
            logger.error("cannot refresh since `datafileUrl` is not provided")
            return
        }

        statuses.refreshInProgress = true

        try? fetchDatafileContent(
            from: datafileUrl,
            handleDatafileFetch: handleDatafileFetch
        ) { [weak self] result in
            guard let self else {
                return
            }

            switch result {
                case .success(let datafileContent):
                    let currentRevision = self.getRevision()
                    let newRevision = datafileContent.revision
                    let isNotSameRevision = currentRevision != newRevision

                    self.datafileReader = DatafileReader(datafileContent: datafileContent)
                    logger.info("refreshed datafile")

                    self.emitter.emit(.refresh)

                    if isNotSameRevision {
                        self.emitter.emit(.update)
                    }

                    self.statuses.refreshInProgress = false

                case .failure(let error):
                    self.logger.error("failed to refresh datafile", ["error": error])
                    self.statuses.refreshInProgress = false
            }
        }
    }

    public func startRefreshing() {
      refreshQueue.async { [weak self] in
              guard let self else { return }

              guard self.datafileUrl != nil else {
                  self.logger.error("cannot start refreshing since `datafileUrl` is not provided")
                  return
              }

              guard self.refreshTimer == nil else {
                  self.logger.warn("refreshing has already started")
                  return
              }

              guard let refreshInterval = self.refreshInterval else {
                  self.logger.warn("no `refreshInterval` option provided")
                  return
              }

              let timer = DispatchSource.makeTimerSource(queue: self.refreshQueue)
              timer.schedule(deadline: .now() + refreshInterval, repeating: refreshInterval)
              timer.setEventHandler { [weak self] in
                  self?.refresh()
              }
              timer.resume()

              self.refreshTimer = timer
          }
    }

    public func stopRefreshing() {
      refreshQueue.async { [weak self] in
          guard let self else { return }

          guard let timer = self.refreshTimer else {
              self.logger.warn("refreshing has not started yet")
              return
          }

          timer.cancel()
          self.refreshTimer = nil
          self.logger.warn("refreshing has stopped")
      }
    }
}
