//
//  main.m
//  NPAuthenticator
//
//  Created by Nickolas Pylarinos Stamatelatos on 28/09/2018.
//  Copyright © 2018 Nickolas Pylarinos Stamatelatos. All rights reserved.
//

#import <syslog.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

/* defines */
#define ICON_ARGUMENT_INDEX 2   // icon
#define EXEC_ARGUMENT_INDEX 1   // executable
#define SMJOBBLESSHELPER_BUNDLE_ID @"npyl.NPTask.SMJobBlessHelper"

/*
 * Helper Function
 */
BOOL blessHelperWithLabel(NSString *label, char *icon, char *prompt, NSError **error)
{
    BOOL result = NO;
    
//    printf("SM: %s\n", icon);
    
    AuthorizationItem right = { kAuthorizationRightExecute, 0, nil, 0 };
    AuthorizationRights authRights  = { 1, &right };
    AuthorizationFlags flags  = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    AuthorizationEnvironment authEnvironment = { 0, nil };
    AuthorizationItem kAuthEnv[2];
    authEnvironment.items = kAuthEnv;
    
    AuthorizationRef authRef = nil;
    CFErrorRef outError = nil;

    if (!prompt)
        prompt = "NPAuthenticator wants to make changes.\n\nCheckout NPAuthenticator in GitHub:\n(https://github.com/npyl/NSAuthenticatedTask)";
    else
    {
        prompt = strcat(prompt, " needs administrator privileges.");
    }
    
    kAuthEnv[0].name = kAuthorizationEnvironmentPrompt;
    kAuthEnv[0].valueLength = strlen(prompt);
    kAuthEnv[0].value = prompt;
    kAuthEnv[0].flags = 0;
    authEnvironment.count++;

    if (icon) {
        kAuthEnv[1].name = kAuthorizationEnvironmentIcon;
        kAuthEnv[1].valueLength = strlen(icon);
        kAuthEnv[1].value = icon;
        kAuthEnv[1].flags = 0;
        authEnvironment.count++;
    }
    
    /* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCreate(&authRights, &authEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess)
    {
        syslog(LOG_NOTICE, "Failed to create AuthorizationRef. Error code: %d", (int)status);
    }
    else
    {
        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &outError);
        
        /* get NSError out of CFErrorRef */
        if (*error)
            *error = (__bridge NSError *)outError;
    }
    
    return result;
}

int main(int argc, const char * argv[])
{
    NSError *error = nil;

    if (
        !blessHelperWithLabel(SMJOBBLESSHELPER_BUNDLE_ID,
                              (char *)argv[ICON_ARGUMENT_INDEX],
                              (char *)argv[EXEC_ARGUMENT_INDEX],
                              &error)
        )
    {
        syslog(LOG_NOTICE, "Failed to bless helper. Error: %s", error.localizedDescription.UTF8String);
        return (-1);
    }
    
    return 0;
}
