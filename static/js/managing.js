var ManagePanel = {
 NAME_SPACES: {},
 CurrentPanel : "",
 show_panel_system: function(Key){    
        var new_function = function(Data){    
                
                 $("#panel").html(Data);                                   
        };           
         var ObjSession = gapi.auth.getToken("token",null); 
        if(ObjSession){
                var Session = ObjSession.access_token;
                $.ajax(
                    {
                            url: "http://" + HOST +"/command/get_expert_info/"+Session+"/"+Key+"/",
                            success: new_function
                    }
                );
        }
     
     
 },
 show_own_expert_system_button: function(key, value){
                       ManagePanel.NAME_SPACES[key] = 1;
                       
                       var click = 'javascript:ManagePanel.show_panel_system("'+key+'")';
//                         <li>
//                 <a href="#old" class="e_doc_title">
//                     <i class="icon-chevron-right"></i><b>Big Data</b></a>
//                 
//                 </li>
                       var Res ="<li><a  href='"+click+"' class='e_doc_title' ><i class=\"icon-chevron-right\"></i>"+ value +"</a></li>";
                       $( Res ).appendTo( "#you_expert_systems" );

        
  
    
 },    
 start: function(){
            var ObjSession = gapi.auth.getToken("token",null); 
            if(ObjSession){
                                    var Session = ObjSession.access_token;                            
                                    var new_function = function(Data){
                                                            var array = $.map(Data, function(value, key) {
                                                                        ManagePanel.show_own_expert_system_button(key, value);
                                                            });                                                            
                                                        };           
                                    $.ajax(
                                        {
                                            dataType: "json",
                                            url: "http://" + HOST +"/command/create_managing_command_session/"+Session,
                                            success: new_function
                                        }
                                    );
                        
                                                          
                        
                        
           }
    }
           
}
                        