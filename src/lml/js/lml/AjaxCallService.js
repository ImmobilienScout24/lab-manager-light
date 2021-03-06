angular.module('lml-app')
  .service('AjaxCallService', function AjaxCallService($http, $log) {
    "use strict";

    function get(path, success, error) {
      return $http.get(path, {headers: {Accept: 'application/json' }})
        .success(success)
        .error(error);
    }

    function post(path, userQuery, successHandler, failureHandler) {

      function failure(data, status, headers, config) {
        $log.error("an error occured while sending ajax request - response status: " + status);
        if (failureHandler) {
          failureHandler(data);
        }
      }

      return $http.post(path, userQuery, {headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' }})
        .success(successHandler)
        .error(failure);
    }

    return {
      post: post,
      get: get
    };
  });