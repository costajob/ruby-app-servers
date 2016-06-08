worker_processes 8
listen 9292
timeout 60
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true
check_client_connection false
pid File.expand_path('../../tmp/pids/unicorn.pid', __FILE__)
stderr_path File::NULL
stdout_path File::NULL
