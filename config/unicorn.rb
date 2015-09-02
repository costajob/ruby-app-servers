worker_processes 3
timeout 60
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true
check_client_connection false
