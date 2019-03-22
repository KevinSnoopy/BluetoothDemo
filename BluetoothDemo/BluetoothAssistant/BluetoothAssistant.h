//
//  BluetoothAssistant.h
//  BluetoothDemo
//
//  Created by kevin on 2019/3/19.
//  Copyright © 2019 kevin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BLUETOOTHTYPE) {
    CONNECTNONE = 1,
    CONNECTSUCCESS = 2,
    DISCONNECT = 3,
    CONNECTFAIL = 4,
    CONNECTWRITE = 5,
    CONNECTERROR
};

typedef NS_ENUM(NSInteger, SEARCHTYPE) {
    SEARCHING = 1,
    SEARCHEND
};

@protocol BluetoothProtocol <NSObject>
@optional
/**
 手机蓝牙状态
 */
- (void)updateState:(CBManagerState)state;
/**
 搜索到的蓝牙设备信息
 */
- (void)bluetooth:(SEARCHTYPE)type List:(NSArray *__nullable)list;
/**
 返回蓝牙连接状态和数据
 */
- (void)bluetooth:(BLUETOOTHTYPE)type Data:(NSData *__nullable)data;

@end

@interface BluetoothAssistant : NSObject

/**
 搜索蓝牙
 */
+ (void)scanForPeripherals;
/**
 设置代理
 */
+ (void)setProtocol:(id<BluetoothProtocol> __nullable)protocol;
/**
 选择连接蓝牙
 */
+ (void)connectPeripheral:(NSString *)identity;
/**
 发送数据
 */
+ (void)postMessage:(Byte[])byte Count:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
