﻿using System;
using System.Collections.Generic;

namespace Sqlcollaborative.Dbatools.Message
{
    /// <summary>
    /// Carrier class, designed to hold an arbitrary number of exceptions. Used for exporting to XML in nice per-incident packages.
    /// </summary>
    [Serializable]
    public class DbatoolsExceptionRecord
    {
        /// <summary>
        /// Runspace where shit happened.
        /// </summary>
        public Guid Runspace;

        /// <summary>
        /// The computer name the exception was written on
        /// </summary>
        public string ComputerName;

        /// <summary>
        /// When did things go bad?
        /// </summary>
        public DateTime Timestamp;

        /// <summary>
        /// Name of the function, where fail happened.
        /// </summary>
        public string FunctionName;

        /// <summary>
        /// The module of the function where fail happened
        /// </summary>
        public string ModuleName;

        /// <summary>
        /// The tags that were applied to the failure
        /// </summary>
        public List<string> Tags = new List<string>();

        /// <summary>
        /// The message the poor user was shown.
        /// </summary>
        public string Message;

        /// <summary>
        /// Displays the name of the exception, the make scanning exceptions easier.
        /// </summary>
        public string ExceptionType
        {
            get
            {
                try
                {
                    if (Exceptions.Count > 0)
                    {
                        if ((Exceptions[0].GetException().GetType().FullName == "System.Exception") && (Exceptions[0].InnerException != null))
                            return Exceptions[0].InnerException.GetException().GetType().Name;

                        return Exceptions[0].GetException().GetType().Name;
                    }
                }
                catch { }

                return "";
            }
            set
            {

            }
        }

        /// <summary>
        /// The target object of the first exception in the list, if any
        /// </summary>
        public object TargetObject
        {
            get
            {
                if (Exceptions.Count > 0)
                    return Exceptions[0].TargetObject;
                return null;
            }
            set
            {

            }
        }

        /// <summary>
        /// List of Exceptions that are part of the incident (usually - but not always - only one).
        /// </summary>
        public List<DbatoolsException> Exceptions = new List<DbatoolsException>();

        /// <summary>
        /// Creates an empty container. Ideal for the homeworker who loves doing it all himself.
        /// </summary>
        public DbatoolsExceptionRecord()
        {

        }

        /// <summary>
        /// Creates a container filled with the first exception.
        /// </summary>
        /// <param name="Exception"></param>
        public DbatoolsExceptionRecord(DbatoolsException Exception)
        {
            Runspace = Exception.Runspace;
            Timestamp = Exception.Timestamp;
            FunctionName = Exception.FunctionName;
            Message = Exception.Message;
        }

        /// <summary>
        /// Creates a container filled with the meta information but untouched by exceptions
        /// </summary>
        /// <param name="Runspace">The runspace where it all happened</param>
        /// <param name="ComputerName">The computer the error was recorded</param>
        /// <param name="Timestamp">When did it happen?</param>
        /// <param name="FunctionName">Where did it happen?</param>
        /// <param name="ModuleName">The name of the module where fail happened</param>
        /// <param name="Tags">The tags that were assigned to the failure</param>
        /// <param name="Message">What did the witness have to say?</param>
        public DbatoolsExceptionRecord(Guid Runspace, string ComputerName, DateTime Timestamp, string FunctionName, string ModuleName, List<string> Tags, string Message)
        {
            this.Runspace = Runspace;
            this.ComputerName = ComputerName;
            this.Timestamp = Timestamp;
            this.FunctionName = FunctionName;
            this.ModuleName = ModuleName;
            this.Tags = Tags;
            this.Message = Message;
        }
    }
}