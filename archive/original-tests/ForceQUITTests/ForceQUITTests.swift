//
//  ForceQUITTests.swift
//  ForceQUITTests
//
//  SWARM 2.0 AI Development Framework
//  Core Application Tests
//
//  Created by SWARM AI Agents  
//  Copyright © 2024 ForceQUIT. All rights reserved.
//

import XCTest
@testable import ForceQUITCore
@testable import ForceQUITSecurity
@testable import ForceQUITAnalytics

final class ForceQUITTests: XCTestCase {
    
    var processManager: ProcessManager!
    var securityManager: SecurityManager!
    
    override func setUpWithError() throws {
        processManager = ProcessManager.shared
        securityManager = SecurityManager.shared
    }
    
    override func tearDownWithError() throws {
        processManager.stopMonitoring()
        processManager = nil
        securityManager = nil
    }
    
    // MARK: - Process Manager Tests
    
    func testProcessManagerInitialization() throws {
        XCTAssertNotNil(processManager)
        XCTAssertFalse(processManager.isMonitoring)
        XCTAssertEqual(processManager.runningProcesses.count, 0)
        XCTAssertEqual(processManager.systemLoad, 0.0)
    }
    
    func testProcessManagerStartStop() throws {
        processManager.startMonitoring()
        XCTAssertTrue(processManager.isMonitoring)
        
        processManager.stopMonitoring()
        XCTAssertFalse(processManager.isMonitoring)
    }
    
    func testProcessInfoCreation() throws {
        let processInfo = ProcessInfo(
            pid: 1234,
            name: "TestApp",
            bundleID: "com.test.app",
            cpuUsage: 15.5,
            memoryUsage: 1024000,
            isResponding: true,
            canSafeRestart: false
        )
        
        XCTAssertEqual(processInfo.pid, 1234)
        XCTAssertEqual(processInfo.name, "TestApp")
        XCTAssertEqual(processInfo.bundleID, "com.test.app")
        XCTAssertEqual(processInfo.cpuUsage, 15.5, accuracy: 0.1)
        XCTAssertEqual(processInfo.memoryUsage, 1024000)
        XCTAssertTrue(processInfo.isResponding)
        XCTAssertFalse(processInfo.canSafeRestart)
    }
    
    // MARK: - Security Manager Tests
    
    func testSecurityManagerInitialization() throws {
        XCTAssertNotNil(securityManager)
        XCTAssertEqual(securityManager.securityStatus, .checking)
    }
    
    func testSecurityStatusEnum() throws {
        let checking = SecurityStatus.checking
        let authorized = SecurityStatus.authorized
        let unauthorized = SecurityStatus.unauthorized
        let error = SecurityStatus.error("Test error")
        
        XCTAssertNotNil(checking)
        XCTAssertNotNil(authorized)
        XCTAssertNotNil(unauthorized)
        XCTAssertNotNil(error)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMonitoringOverhead() throws {
        measure {
            processManager.startMonitoring()
            Thread.sleep(forTimeInterval: 0.1)
            processManager.stopMonitoring()
        }
    }
    
    // MARK: - Integration Tests
    
    func testSystemInitialization() throws {
        let expectation = expectation(description: "System initialization")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulate system startup
            self.processManager.startMonitoring()
            self.securityManager.validatePermissions()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
        XCTAssertTrue(processManager.isMonitoring)
    }
}