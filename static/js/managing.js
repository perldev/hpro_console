var ManagePanel = {
 NAME_SPACES: {},
 CurrentPanel : "",
 show_panel_system: function(Key){    
        var ObjSession = gapi.auth.getToken("token",null); 
        if(ObjSession){
               
                var Session = ObjSession.access_token;
                var new_function = function(Data){    
                    $("#panel").html(Data);                                   
                    $("#monitoring").hide("fast");
                    vm_statistic.change_namespace(Key, Session);
                };        
                
                $.ajax(
                    {
                            url: "http://" + HOST +"/command/get_expert_info/"+Session+"/"+Key+"/",
                            success: new_function
                    }
                );
         }
     
     
 },
 restore_description: function(){
     
      $("#change_description_form").hide("fast");
      var Text = $("#description_text").html();
      $("#change_description_textarea").html(Text);

      $("#description").slideDown("fast");

     
  },
  save_description: function(Id){
     
    
      
      var Text = $("#change_description_textarea").val();
      var new_function = function (Data){
            $("#change_description_form").hide("fast");
            $("#description_text").html(Text);
            $("#description").slideDown("fast");
      };      
      var ObjSession = gapi.auth.getToken("token",null); 
      
      if(ObjSession){
            var Session = ObjSession.access_token;      
            
            $.ajax(
                
                    {
                        url: "http://" + HOST +"/command/update_desc/"+Session+"/"+Id,
                        type: "POST",
                        data: {"description": Text},
                        success: new_function,
                        error: default_alert
                    }
                  );
      }
    

     
  },
  open_description: function(){
      $("#description").hide("fast");
      var Text = $("#description_text").html();
      $("#change_description_textarea").val(Text);
      $("#change_description_form").slideDown("fast");
     
     
 },
 restore_salt: function(){
     
      $("#change_salt_form").hide("fast");
      $("#salt").slideDown("fast");

     
  },
  save_salt: function(Id){
     
    
      
      var Text = $("#change_salt_text").val();
      var new_function = function (Data){
            ManagePanel.restore_salt();
      };      
      var ObjSession = gapi.auth.getToken("token",null); 
      
      if(ObjSession){
            var Session = ObjSession.access_token;      
            
            $.ajax(
                
                    {
                        url: "http://" + HOST +"/command/update_salt/"+Session+"/"+Id,
                        type: "POST",
                        data: {"salt": Text},
                        success: new_function,
                        error: default_alert
                    }
                  );
      }
    

     
  },
  open_salt: function(){
      $("#salt").hide("fast");
      $("#change_salt_form").slideDown("fast");
     
     
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
                        