import Foundation

public extension FeaturevisorInstance {

    // MARK: - Refresh

    func refresh() {
        logger.debug("refreshing datafile")

        if statuses.refreshInProgress {
            logger.warn("refresh in progress, skipping");
            return
        }

        guard let datafileUrl else {
            logger.error("cannot refresh since `datafileUrl` is not provided")
            return
        }

        statuses.refreshInProgress = true

        try? fetchDatafileContent(from: datafileUrl, handleDatafileFetch: handleDatafileFetch) { [weak self] result in
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

    func startRefreshing() {

        guard let datafileUrl else {
            logger.error("cannot start refreshing since `datafileUrl` is not provided")
            return
        }

        guard timer == nil else {
            logger.warn("refreshing has already started")
            return
        }

        guard let refreshInterval else {
            logger.warn("no `refreshInterval` option provided")
            return
        }

        DispatchQueue.global().async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true) { _ in
                self?.refresh()
            }

            if let timer = self?.timer {
                RunLoop.current.add(timer, forMode: .common)
                RunLoop.current.run()
            }
        }
    }

    func stopRefreshing() {

        DispatchQueue.global().async { [weak self] in

            guard let intervalId = self?.timer else {
                self?.logger.warn("refreshing has not started yet")
                return
            }

            intervalId.invalidate()
            self?.timer = nil
        }

        logger.warn("refreshing has stopped")
    }

}