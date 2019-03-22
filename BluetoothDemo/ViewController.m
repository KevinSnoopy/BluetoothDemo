//
//  ViewController.m
//  BluetoothDemo
//
//  Created by kevin on 2019/3/19.
//  Copyright © 2019 kevin. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothAssistant.h"

@interface ViewController () <BluetoothProtocol>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [BluetoothAssistant setProtocol:self];
    [BluetoothAssistant scanForPeripherals];
}

#pragma mark BluetoothProtocol
- (void)bluetooth:(BLUETOOTHTYPE)type Data:(NSData *)data{
    
}

- (void)bluetooth:(SEARCHTYPE)type List:(NSArray *)list{
    
}

- (void)updateState:(CBManagerState)state{
    
}

@end
