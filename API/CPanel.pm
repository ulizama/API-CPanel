package API::CPanel;

use strict;
use base 'Exporter';
use LWP::UserAgent;
use MIME::Base64;
use URI::Escape;
use JSON;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( createacct modifyacct modifypwd changepackage removeacct cpanel );



sub createacct{
    
    my $connection_params = shift or return _api_error('Connection params missing');
    my $request_params = shift or return _api_error('No request params found');
    
    if( !$request_params->{'username'}
       || !$request_params->{'password'}
       || !$request_params->{'domain'}){
        return _api_error('Some params are missing for createacct');
    }
    
    my $query_string = _build_request_uri( $request_params );
    
    return _send_api_request($connection_params,'createacct',$query_string);
  
    
}


sub modifyacct{
    
    my $connection_params = shift or return _api_error('Connection params missing');
    my $request_params = shift or return _api_error('No request params found');
    
    if( !$request_params->{'user'} ){
        return _api_error('Some params are missing for modifyacct');
    }
    
    my $query_string = _build_request_uri( $request_params );
    
    return _send_api_request($connection_params,'modifyacct',$query_string);
  
    
}


sub removeacct{
    
    my $connection_params = shift or return _api_error('Connection params missing');
    my $request_params = shift or return _api_error('No request params found');
    
    if( !$request_params->{'user'} ){
        return _api_error('Some params are missing for removeacct');
    }
    
    my $query_string = _build_request_uri( $request_params );
    
    return _send_api_request($connection_params,'removeacct',$query_string);
  
    
}


sub modifypwd{
	
    my $connection_params = shift or return _api_error('Connection params missing');
    my $request_params = shift or return _api_error('No request params found');
    
    if( !$request_params->{'user'}
       || !$request_params->{'pass'} ){
        return _api_error('Some params are missing for modifyacct');
    }
    
    my $query_string = _build_request_uri( $request_params );
    
    return _send_api_request($connection_params,'passwd',$query_string);	
	
}


sub changepackage{
	
    my $connection_params = shift or return _api_error('Connection params missing');
    my $request_params = shift or return _api_error('No request params found');
    
    if( !$request_params->{'user'}
       || !$request_params->{'pkg'} ){
        return _api_error('Some params are missing for changepackage');
    }
    
    my $query_string = _build_request_uri( $request_params );
    
    return _send_api_request($connection_params,'changepackage',$query_string);	
	
}


sub cpanel{
	
    my $connection_params = shift or return _api_error('Connection params missing');
    my $request_params = shift or return _api_error('No request params found');
		
    if( !$request_params->{'module'}
       || !$request_params->{'function'}
			 || !$request_params->{'user'} ){			
        return _api_error('Some params are missing for cpanel');
    }
		
		$request_params->{'cpanel_jsonapi_module'} = delete $request_params->{'module'};
		$request_params->{'cpanel_jsonapi_func'} = delete $request_params->{'function'};		
    
    my $query_string = _build_request_uri( $request_params );
    
    return _send_api_request($connection_params,'cpanel',$query_string);	
	
}


sub _build_request_uri{
    
    my $args = shift;
    
    return join '&', map { uri_escape($_)."=".uri_escape($args->{$_}) } keys %{$args};
    
}

sub _send_api_request{
    
    my $connection_params = shift or return 0;
    my $function = shift;
    my $query_string = shift;
		my $api_access_portal = shift || 'WHM';

    my $auth = "Basic " . MIME::Base64::encode( $connection_params->{'auth_user'} . ":" . $connection_params->{'auth_passwd'} );
		my $port;

    my $ua = LWP::UserAgent->new;
    
    my $protocol = $connection_params->{'http'} ? "http" : "https";
		
		if( $api_access_portal eq 'CPanel' ){
			$port = $protocol eq "http" ? 2082 : 2083;
		}
		else{
			$port = $protocol eq "http" ? 2086 : 2087;
		}
    
    my $request_url = $protocol . "://" . $connection_params->{'host'} . ":" . $port . '/json-api/' . $function . '?' . $query_string;

    my $request = HTTP::Request->new( GET => $request_url );
    $request->header( Authorization => $auth );    

    my $response = $ua->request($request);
    
    if( $response->is_success ){
        my $api_response = from_json($response->content);
				
				if( $function eq 'cpanel' ){
					
					use Data::Dumper;
					warn Dumper($api_response);
					
					if( $api_response->{'cpanelresult'}->{error} || ( $api_response->{'type'} && $api_response->{data}->{result} == 0 ) ){
						return 0, $api_response->{'type'} ? $api_response->{data}->{reason} : $api_response->{'cpanelresult'}->{error};						
					}

					return 1, $api_response->{'cpanelresult'}->{data};
				}
				else{
				
					my $rr = $api_response->{'result'}->[0];
				
					if( $function eq 'passwd' ){
						$rr = $api_response->{'passwd'}->[0];
					}				
        
					if( $rr ){
            return $rr->{'status'}, $rr->{'statusmsg'}, $api_response;
					}
					else{
            return 0, 'Unknown', $api_response;
					}
        
					return 1, $api_response;
				}
    }
    else{
        return _api_error('Request error: ' . $response->as_string);
    }
        
    
}    


sub _api_error{
    
    my $error = shift;
    
    return 0, $error, {};
    
}

1;
