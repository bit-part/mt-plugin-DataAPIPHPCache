<?php
  define('DataAPICacheDirName', 'data-api-php-cache');
  $include_endpoints = array('entries', 'categories', 'comments');
  $query_string = isset($_SERVER['QUERY_STRING']) ? $_SERVER['QUERY_STRING'] : '';
  $path_info = isset($_SERVER['PATH_INFO']) ? $_SERVER['PATH_INFO'] : '';
  $headers = getallheaders();
  $post_header = "Content-Type: application/x-www-form-urlencoded";
  if (!empty($headers{'X-MT-Authorization'}) && preg_match('/^MTAuth accessToken/', $headers{'X-MT-Authorization'})) {
    $post_header .= "\r\n". "X-MT-Authorization:" . $headers{'X-MT-Authorization'};
  }
  $cache_disabled = true;
  if ($path_info) {
    foreach ($include_endpoints as $value) {
      if (strpos($path_info, $value)) {
        $cache_disabled = false;
        break;
      }
    }
    if ($cache_disabled) {
      $error_message = array(
        'error' => array(
          'code' => '900',
          'message' => 'Can not use this cache system to the request.'
        )
      );
      echo(json_encode($error_message));
      exit();
    }
  }
  $file_name = ($query_string) ? '/' . md5($query_string) . '.json' : '/index.json';
  $data_api_script = '<mt:CGIPath><mt:Var name="config.DataAPIScript">';
  $data_api_cache_path = '<mt:If name="config.SupportDirectoryPath"><mt:Var name="config.SupportDirectoryPath"><mt:Else><mt:Var name="config.StaticFilePath">/support</mt:If>/' . DataAPICacheDirName;
  $cache_write = false;
  $cache_file = $data_api_cache_path . $path_info . $file_name;
  $cache_dir = dirname($cache_file);
  if (file_exists($cache_file)) {
    readfile($cache_file);
  }
  else {
    $url = $data_api_script . $path_info . '?' . $query_string;
    $context = stream_context_create(array(
      'http' => array(
        'method' => 'GET',
        'header' => $post_header,
        'ignore_errors' => true,
      )
    ));
    $response = @file_get_contents($url, false, $context);
    $response_json = json_decode($response);
    if (isset($response_json)) {
      $response_error = isset($response_json->{'error'}) ? $response_json->{'error'} : NULL;
      if (!isset($response_error)) {
        if (!file_exists($cache_dir) and !mkdir($cache_dir, 0777, true)) {
          die('Failed to create folders.');
        }
        file_put_contents($cache_file, $response);
      }
    }
    echo($response);
  }
  exit();
?>