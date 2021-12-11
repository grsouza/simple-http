import Foundation

public struct StatusCodeValidator: ResponseInterceptor {
  public let statusCodes: Range<Int>

  public init(statusCodes: Range<Int> = 200..<300) {
    self.statusCodes = statusCodes
  }

  public func intercept(_ client: HTTPClientProtocol, _ result: Result<Response, Error>)
    async throws
    -> Response
  {
    let response = try result.get()
    guard statusCodes.contains(response.statusCode) else {
      throw APIError(response: response)
    }
    return response
  }
}

public struct RequestRetrier: ResponseInterceptor {
  public init() {}

  public func intercept(_ client: HTTPClientProtocol, _ result: Result<Response, Error>)
    async throws
    -> Response
  {
    guard shouldRetry(result), let endpoint = result.value?.endpoint else {
      return try result.get()
    }

    return try await client.request(endpoint)
  }

  private func shouldRetry(_ result: Result<Response, Error>) -> Bool {
    switch result {
    case .success(let response):
      return defaultRetryableHTTPMethods.contains(response.endpoint.method)
        && defaultRetryableHTTPStatusCode.contains(response.statusCode)
    case .failure(let error as URLError):
      return defaultRetryableURLErrorCodes.contains(error.code)
    default:
      return false
    }
  }
}

let defaultRetryableHTTPMethods: Set<HTTPMethod> = [
  .delete,
  .get,
  .head,
  .options,
  .put,
  .trace,
]

let defaultRetryableHTTPStatusCode: Set<Int> = [
  408,
  500,
  502,
  503,
  504,
]

let defaultRetryableURLErrorCodes: Set<URLError.Code> = [  // [Security] App Transport Security disallowed a connection because there is no secure network connection.
  //   - [Disabled] ATS settings do not change at runtime.
  // .appTransportSecurityRequiresSecureConnection,
  // [System] An app or app extension attempted to connect to a background session that is already connected to a
  // process.
  //   - [Enabled] The other process could release the background session.
  .backgroundSessionInUseByAnotherProcess,

  // [System] The shared container identifier of the URL session configuration is needed but has not been set.
  //   - [Disabled] Cannot change at runtime.
  // .backgroundSessionRequiresSharedContainer,
  // [System] The app is suspended or exits while a background data task is processing.
  //   - [Enabled] App can be foregrounded or launched to recover.
  .backgroundSessionWasDisconnected,

  // [Network] The URL Loading system received bad data from the server.
  //   - [Enabled] Server could return valid data when retrying.
  .badServerResponse,

  // [Resource] A malformed URL prevented a URL request from being initiated.
  //   - [Disabled] URL was most likely constructed incorrectly.
  // .badURL,
  // [System] A connection was attempted while a phone call is active on a network that does not support
  // simultaneous phone and data communication (EDGE or GPRS).
  //   - [Enabled] Phone call could be ended to allow request to recover.
  .callIsActive,

  // [Client] An asynchronous load has been canceled.
  //   - [Disabled] Request was cancelled by the client.
  // .cancelled,
  // [File System] A download task couldn’t close the downloaded file on disk.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .cannotCloseFile,
  // [Network] An attempt to connect to a host failed.
  //   - [Enabled] Server or DNS lookup could recover during retry.
  .cannotConnectToHost,

  // [File System] A download task couldn’t create the downloaded file on disk because of an I/O failure.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .cannotCreateFile,
  // [Data] Content data received during a connection request had an unknown content encoding.
  //   - [Disabled] Server is unlikely to modify the content encoding during a retry.
  // .cannotDecodeContentData,
  // [Data] Content data received during a connection request could not be decoded for a known content encoding.
  //   - [Disabled] Server is unlikely to modify the content encoding during a retry.
  // .cannotDecodeRawData,
  // [Network] The host name for a URL could not be resolved.
  //   - [Enabled] Server or DNS lookup could recover during retry.
  .cannotFindHost,

  // [Network] A request to load an item only from the cache could not be satisfied.
  //   - [Enabled] Cache could be populated during a retry.
  .cannotLoadFromNetwork,

  // [File System] A download task was unable to move a downloaded file on disk.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .cannotMoveFile,
  // [File System] A download task was unable to open the downloaded file on disk.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .cannotOpenFile,
  // [Data] A task could not parse a response.
  //   - [Disabled] Invalid response is unlikely to recover with retry.
  // .cannotParseResponse,
  // [File System] A download task was unable to remove a downloaded file from disk.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .cannotRemoveFile,
  // [File System] A download task was unable to write to the downloaded file on disk.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .cannotWriteToFile,
  // [Security] A client certificate was rejected.
  //   - [Disabled] Client certificate is unlikely to change with retry.
  // .clientCertificateRejected,
  // [Security] A client certificate was required to authenticate an SSL connection during a request.
  //   - [Disabled] Client certificate is unlikely to be provided with retry.
  // .clientCertificateRequired,
  // [Data] The length of the resource data exceeds the maximum allowed.
  //   - [Disabled] Resource will likely still exceed the length maximum on retry.
  // .dataLengthExceedsMaximum,
  // [System] The cellular network disallowed a connection.
  //   - [Enabled] WiFi connection could be established during retry.
  .dataNotAllowed,

  // [Network] The host address could not be found via DNS lookup.
  //   - [Enabled] DNS lookup could succeed during retry.
  .dnsLookupFailed,

  // [Data] A download task failed to decode an encoded file during the download.
  //   - [Enabled] Server could correct the decoding issue with retry.
  .downloadDecodingFailedMidStream,

  // [Data] A download task failed to decode an encoded file after downloading.
  //   - [Enabled] Server could correct the decoding issue with retry.
  .downloadDecodingFailedToComplete,

  // [File System] A file does not exist.
  //   - [Disabled] File system error is unlikely to recover with retry.
  // .fileDoesNotExist,
  // [File System] A request for an FTP file resulted in the server responding that the file is not a plain file,
  // but a directory.
  //   - [Disabled] FTP directory is not likely to change to a file during a retry.
  // .fileIsDirectory,
  // [Network] A redirect loop has been detected or the threshold for number of allowable redirects has been
  // exceeded (currently 16).
  //   - [Disabled] The redirect loop is unlikely to be resolved within the retry window.
  // .httpTooManyRedirects,
  // [System] The attempted connection required activating a data context while roaming, but international roaming
  // is disabled.
  //   - [Enabled] WiFi connection could be established during retry.
  .internationalRoamingOff,

  // [Connectivity] A client or server connection was severed in the middle of an in-progress load.
  //   - [Enabled] A network connection could be established during retry.
  .networkConnectionLost,

  // [File System] A resource couldn’t be read because of insufficient permissions.
  //   - [Disabled] Permissions are unlikely to be granted during retry.
  // .noPermissionsToReadFile,
  // [Connectivity] A network resource was requested, but an internet connection has not been established and
  // cannot be established automatically.
  //   - [Enabled] A network connection could be established during retry.
  .notConnectedToInternet,

  // [Resource] A redirect was specified by way of server response code, but the server did not accompany this
  // code with a redirect URL.
  //   - [Disabled] The redirect URL is unlikely to be supplied during a retry.
  // .redirectToNonExistentLocation,
  // [Client] A body stream is needed but the client did not provide one.
  //   - [Disabled] The client will be unlikely to supply a body stream during retry.
  // .requestBodyStreamExhausted,
  // [Resource] A requested resource couldn’t be retrieved.
  //   - [Disabled] The resource is unlikely to become available during the retry window.
  // .resourceUnavailable,
  // [Security] An attempt to establish a secure connection failed for reasons that can’t be expressed more
  // specifically.
  //   - [Enabled] The secure connection could be established during a retry given the lack of specificity
  //     provided by the error.
  .secureConnectionFailed,

  // [Security] A server certificate had a date which indicates it has expired, or is not yet valid.
  //   - [Enabled] The server certificate could become valid within the retry window.
  .serverCertificateHasBadDate,

  // [Security] A server certificate was not signed by any root server.
  //   - [Disabled] The server certificate is unlikely to change during the retry window.
  // .serverCertificateHasUnknownRoot,
  // [Security] A server certificate is not yet valid.
  //   - [Enabled] The server certificate could become valid within the retry window.
  .serverCertificateNotYetValid,

  // [Security] A server certificate was signed by a root server that isn’t trusted.
  //   - [Disabled] The server certificate is unlikely to become trusted within the retry window.
  // .serverCertificateUntrusted,
  // [Network] An asynchronous operation timed out.
  //   - [Enabled] The request timed out for an unknown reason and should be retried.
  .timedOut,

  // [System] The URL Loading System encountered an error that it can’t interpret.
  //   - [Disabled] The error could not be interpreted and is unlikely to be recovered from during a retry.
  // .unknown,
  // [Resource] A properly formed URL couldn’t be handled by the framework.
  //   - [Disabled] The URL is unlikely to change during a retry.
  // .unsupportedURL,
  // [Client] Authentication is required to access a resource.
  //   - [Disabled] The user authentication is unlikely to be provided by retrying.
  // .userAuthenticationRequired,
  // [Client] An asynchronous request for authentication has been canceled by the user.
  //   - [Disabled] The user cancelled authentication and explicitly took action to not retry.
  // .userCancelledAuthentication,
  // [Resource] A server reported that a URL has a non-zero content length, but terminated the network connection
  // gracefully without sending any data.
  //   - [Disabled] The server is unlikely to provide data during the retry window.
  // .zeroByteResource,
]
