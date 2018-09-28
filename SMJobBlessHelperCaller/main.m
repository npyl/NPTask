//
//  main.m
//  SMJobBlessHelperCaller
//
//  Created by Nickolas Pylarinos Stamatelatos on 28/09/2018.
//  Copyright © 2018 Nickolas Pylarinos Stamatelatos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

/*
 * Helper Function
 */
BOOL blessHelperWithLabel( NSString * label, NSError ** error )
{
    BOOL result = NO;
    
    AuthorizationItem authItem        = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights    = { 1, &authItem };
    AuthorizationFlags flags        =    kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed    |
    kAuthorizationFlagPreAuthorize    |
    kAuthorizationFlagExtendRights;
    
    AuthorizationRef authRef = NULL;
    
    CFErrorRef outError = nil;
    
    /* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess) {
        NSLog( @"Failed to create AuthorizationRef. Error code: %d", (int)status );
        
    } else {
        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        NSLog(@"%@", label);
        result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &outError);
        
        /* get NSError out of CFErrorRef */
        *error = (__bridge NSError *)outError;
    }
    
    return result;
}

int main(int argc, const char * argv[])
{
#define SMJOBBLESSHELPER_BUNDLE_ID @"npyl.NPTask.SMJobBlessHelper"
    
    NSError *error = nil;
    
    if (!blessHelperWithLabel(SMJOBBLESSHELPER_BUNDLE_ID, &error))
    {
        NSLog(@"Failed to bless helper. Error: %@", error);
        return (-1);
    }
    
    NSLog(@"Helper available.");
    
    return 0;
    //    return NSApplicationMain(argc, argv);
}