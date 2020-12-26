#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import { LakeStack } from '../lib/lake-stack';

const app = new cdk.App();
new LakeStack(app, 'LakeStack');
