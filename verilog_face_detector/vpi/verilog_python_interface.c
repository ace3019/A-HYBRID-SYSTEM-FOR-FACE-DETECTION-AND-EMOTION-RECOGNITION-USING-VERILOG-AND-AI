#include <vpi_user.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

// Helper to get integer value from argument
int get_arg_val(vpiHandle arg) {
    s_vpi_value val;
    val.format = vpiIntVal;
    vpi_get_value(arg, &val);
    return val.value.integer;
}

// Task to send ROI to Python server
// Usage: $send_roi_for_emotion(x, y, w, h);
// Note: We are omitting the memory argument for simplicity in this VPI 
// and assuming the Python side just needs coordinates or we rely on the test setup.
// To truly send pixels, we'd need to iterate the Verilog memory array.
static PLI_INT32 send_roi_calltf(PLI_BYTE8* user_data) {
    vpiHandle systf_handle, args_iter, arg;
    int x, y, w, h;
    
    (void)user_data;  // Mark as unused to avoid warning
    
    systf_handle = vpi_handle(vpiSysTfCall, NULL);
    args_iter = vpi_iterate(vpiArgument, systf_handle);
    
    if (args_iter == NULL) {
        vpi_printf("ERROR: $send_roi_for_emotion requires arguments (x, y, w, h)\n");
        return 0;
    }
    
    // Get arguments
    arg = vpi_scan(args_iter); x = get_arg_val(arg);
    arg = vpi_scan(args_iter); y = get_arg_val(arg);
    arg = vpi_scan(args_iter); w = get_arg_val(arg);
    arg = vpi_scan(args_iter); h = get_arg_val(arg);
    
    vpi_free_object(args_iter);
    
    vpi_printf("VPI: Sending ROI (x=%d, y=%d, w=%d, h=%d)\n", x, y, w, h);
    
    // Connect to Python server
    int sock = 0;
    struct sockaddr_in serv_addr;
    char buffer[1024] = {0};
    
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        vpi_printf("VPI ERROR: Socket creation error\n");
        return 0;
    }
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(8888);
    
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr) <= 0) {
        vpi_printf("VPI ERROR: Invalid address\n");
        return 0;
    }
    
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        vpi_printf("VPI ERROR: Connection Failed. Is emotion_server.py running?\n");
        return 0;
    }
    
    // Send ROI command
    char msg[256];
    sprintf(msg, "ROI %d %d %d %d\n", x, y, w, h);
    send(sock, msg, strlen(msg), 0);
    
    // Wait for response
    int valread = read(sock, buffer, 1024);
    if (valread > 0) {
        buffer[valread] = '\0';
        // Remove newline
        char *pos;
        if ((pos=strchr(buffer, '\n')) != NULL)
            *pos = '\0';
            
        vpi_printf("\n--------------------------------------------------\n");
        vpi_printf("VPI: Received Result: %s\n", buffer);
        vpi_printf("--------------------------------------------------\n\n");
    } else {
        vpi_printf("VPI ERROR: No response from server\n");
    }
    
    close(sock);
    return 0;
}

// Registration
void send_roi_register(void) {
    s_vpi_systf_data tf_data;
    tf_data.type = vpiSysTask;
    tf_data.sysfunctype = 0;
    tf_data.tfname = "$send_roi_for_emotion";
    tf_data.calltf = send_roi_calltf;
    tf_data.compiletf = 0;
    tf_data.sizetf = 0;
    tf_data.user_data = 0;
    vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
    send_roi_register,
    0
};
