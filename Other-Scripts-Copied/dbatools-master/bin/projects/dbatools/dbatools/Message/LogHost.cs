﻿using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Management.Automation;

namespace Sqlcollaborative.Dbatools.Message
{
    /// <summary>
    /// Provides static information storage for logging related settings, as well as housing the logging queues.
    /// </summary>
    public static class LogHost
    {
        #region Defines
        /// <summary>
        /// The maximum numbers of error records maintained in-memory.
        /// </summary>
        public static int MaxErrorCount = 128;

        /// <summary>
        /// The maximum number of messages that can be maintained in the in-memory message queue
        /// </summary>
        public static int MaxMessageCount = 1024;

        /// <summary>
        /// The maximum size of a given logfile. When reaching this limit, the file will be abandoned and a new log created. Set to 0 to not limit the size.
        /// </summary>
        public static int MaxMessagefileBytes = 5242880; // 5MB

        /// <summary>
        /// The maximum number of logfiles maintained at a time. Exceeding this number will cause the oldest to be culled. Set to 0 to disable the limit.
        /// </summary>
        public static int MaxMessagefileCount = 5;

        /// <summary>
        /// The maximum size all error files combined may have. When this number is exceeded, the oldest entry is culled.
        /// </summary>
        public static int MaxErrorFileBytes = 20971520; // 20MB

        /// <summary>
        /// This is the upper limit of length all items in the log folder may have combined across all processes.
        /// </summary>
        public static int MaxTotalFolderSize = 104857600; // 100MB

        /// <summary>
        /// Path to where the logfiles live.
        /// </summary>
        public static string LoggingPath;

        /// <summary>
        /// Any logfile older than this will automatically be cleansed
        /// </summary>
        public static TimeSpan MaxLogFileAge = new TimeSpan(7, 0, 0, 0);

        /// <summary>
        /// Governs, whether a log file for the system messages is written
        /// </summary>
        public static bool MessageLogFileEnabled = true;

        /// <summary>
        /// Governs, whether a log of recent messages is kept in memory
        /// </summary>
        public static bool MessageLogEnabled = true;

        /// <summary>
        /// Governs, whether log files for errors are written
        /// </summary>
        public static bool ErrorLogFileEnabled = true;

        /// <summary>
        /// Governs, whether a log of recent errors is kept in memory
        /// </summary>
        public static bool ErrorLogEnabled = true;
        #endregion Defines

        #region Queues
        private static ConcurrentQueue<DbatoolsExceptionRecord> ErrorRecords = new ConcurrentQueue<DbatoolsExceptionRecord>();

        private static ConcurrentQueue<LogEntry> LogEntries = new ConcurrentQueue<LogEntry>();

        /// <summary>
        /// The outbound queue for errors. These will be processed and written to xml
        /// </summary>
        public static ConcurrentQueue<DbatoolsExceptionRecord> OutQueueError = new ConcurrentQueue<DbatoolsExceptionRecord>();

        /// <summary>
        /// The outbound queue for logs. These will be processed and written to logfile
        /// </summary>
        public static ConcurrentQueue<LogEntry> OutQueueLog = new ConcurrentQueue<LogEntry>();
        #endregion Queues

        #region Access Queues
        /// <summary>
        /// Retrieves a copy of the Error stack
        /// </summary>
        /// <returns>All errors thrown by functions using the message or flowcontrol system</returns>
        public static DbatoolsExceptionRecord[] GetErrors()
        {
            DbatoolsExceptionRecord[] temp = new DbatoolsExceptionRecord[ErrorRecords.Count];
            ErrorRecords.CopyTo(temp, 0);
            return temp;
        }

        /// <summary>
        /// Retrieves a copy of the message log
        /// </summary>
        /// <returns>All messages logged this session.</returns>
        public static LogEntry[] GetLog()
        {
            LogEntry[] temp = new LogEntry[LogEntries.Count];
            LogEntries.CopyTo(temp, 0);
            return temp;
        }

        /// <summary>
        /// Write an error record to the log
        /// </summary>
        /// <param name="Record">The actual error record as powershell wrote it</param>
        /// <param name="FunctionName">The name of the function writing the error</param>
        /// <param name="ModuleName">The name of the module the function writing the error came from</param>
        /// <param name="Tags">The tags that were assigned to the error event</param>
        /// <param name="Timestamp">When was the error written</param>
        /// <param name="Message">What message was passed to the user</param>
        /// <param name="Runspace">The runspace the message was written from</param>
        /// <param name="ComputerName">The computer the error was written on</param>
        public static void WriteErrorEntry(ErrorRecord[] Record, string FunctionName, string ModuleName, List<string> Tags, DateTime Timestamp, string Message, Guid Runspace, string ComputerName)
        {
            DbatoolsExceptionRecord tempRecord = new DbatoolsExceptionRecord(Runspace, ComputerName, Timestamp, FunctionName, ModuleName, Tags, Message);
            foreach (ErrorRecord rec in Record)
            {
                tempRecord.Exceptions.Add(new DbatoolsException(rec, FunctionName, Timestamp, Message, Runspace, ComputerName));
            }

            if (ErrorLogFileEnabled) { OutQueueError.Enqueue(tempRecord); }
            if (ErrorLogEnabled) { ErrorRecords.Enqueue(tempRecord); }

            DbatoolsExceptionRecord tmp;
            while ((MaxErrorCount > 0) && (ErrorRecords.Count > MaxErrorCount))
            {
                ErrorRecords.TryDequeue(out tmp);
            }
        }

        /// <summary>
        /// Write a new entry to the log
        /// </summary>
        /// <param name="Message">The message to log</param>
        /// <param name="Type">The type of the message logged</param>
        /// <param name="Timestamp">When was the message generated</param>
        /// <param name="FunctionName">What function wrote the message</param>
        /// <param name="ModuleName">What module did the function writing this message come from?</param>
        /// <param name="Tags">The tags that were applied to the message</param>
        /// <param name="Level">At what level was the function written</param>
        /// <param name="Runspace">The runspace the message is coming from</param>
        /// <param name="ComputerName">The computer the message was generated on</param>
        /// <param name="File">The file from which the message was written</param>
        /// <param name="Line">The line on which the message was written</param>
        /// <param name="TargetObject">The object associated with a given message.</param>
        /// <param name="CallStack">The callstack at the moment the message was written.</param>
        /// <param name="Username">The name of the user under which the code being executed</param>
        /// <returns>The entry that is being written</returns>
        public static LogEntry WriteLogEntry(string Message, LogEntryType Type, DateTime Timestamp, string FunctionName, string ModuleName, List<string> Tags, MessageLevel Level, Guid Runspace, string ComputerName, string File, int Line, IEnumerable<CallStackFrame> CallStack, string Username, object TargetObject = null)
        {
            LogEntry temp = new LogEntry(Message, Type, Timestamp, FunctionName, ModuleName, Tags, Level, Runspace, ComputerName, TargetObject, File, Line, CallStack, Username);
            if (MessageLogFileEnabled) { OutQueueLog.Enqueue(temp); }
            if (MessageLogEnabled) { LogEntries.Enqueue(temp); }

            LogEntry tmp;
            while ((MaxMessageCount > 0) && (LogEntries.Count > MaxMessageCount))
            {
                LogEntries.TryDequeue(out tmp);
            }

            return temp;
        }
        #endregion Access Queues
    }
}
