#!/bin/bash
  INIT_SCRIPT=$1
  shift
  JOB_SCRIPT=$1
  shift 
  source /tmp/job/$INIT_SCRIPT
  source /tmp/job/$JOB_SCRIPT "$@"

