// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/http;
import ballerina/time;
import ballerina/lang.runtime;

type User record {
    readonly int id;
    string name;
    int age;
};

public function main(string label, string outputCsvPath) returns error? {
    http:Client loadTestClient = check new ("http://bal.perf.test", retryConfig = {count: 3, interval: 3});

    boolean result = check loadTestClient->get("/serdes/start");
    if result {
        io:println("Client started communication");
    } else {
        io:println("Could not start communication: client creation failed in serdes service");
    }

    map<string> testResults = {};

    boolean finished = false;
    while !finished {
        map<string>?|error res = loadTestClient->get("/serdes/result");
        if res is error {
            io:println("Error occured", res);
        } else if res is map<string> {
            finished = true;
            testResults = res;
        } else {
            io:println("waiting for result...");
        }
        runtime:sleep(60);
    }
    int errorCount = check int:fromString(testResults.get("errorCount"));
    decimal time = check decimal:fromString(testResults.get("time"));
    int sentCount = check int:fromString(testResults.get("sentCount"));
    int receivedCount = check int:fromString(testResults.get("receivedCount"));
    any[] results = [
        label, sentCount, <float>time / <float>receivedCount,
        0, 0, 0, 0, 0, 0, <float>errorCount / <float>sentCount,
        <float>receivedCount / <float>time, 0, 0, time:utcNow()[0], 0, 1];
    check writeResultsToCsv(results, outputCsvPath);
}

function writeResultsToCsv(any[] results, string outputPath) returns error? {
    string[] finalResult = [];
    foreach var result in results {
        finalResult.push(result.toString());
    }
    check io:fileWriteCsv(outputPath, [finalResult], io:APPEND);
}
