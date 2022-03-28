﻿using System;

namespace Sqlcollaborative.Dbatools.Configuration
{
    /// <summary>
    /// The location where a setting was applied
    /// </summary>
    [Flags]
    public enum ConfigScope
    {
        /// <summary>
        /// The configuration is set as default value for the user
        /// </summary>
        UserDefault = 1,

        /// <summary>
        /// The configuration is enforced for the user
        /// </summary>
        UserMandatory = 2,

        /// <summary>
        /// The configuration is set as default value for all users on the system
        /// </summary>
        SystemDefault = 4,

        /// <summary>
        /// The configuration is enforced for all users on the system.
        /// </summary>
        SystemMandatory = 8,

        /// <summary>
        /// The configuration is stored as Json in the per user local machine config directory.
        /// </summary>
        FileUserLocal = 16,

        /// <summary>
        /// The configuration is stored as Json in the per user config directory shared across machines.
        /// </summary>
        FileUserShared = 32,

        /// <summary>
        /// The configuration is stored as Json in the local computer config directory.
        /// </summary>
        FileSystem = 64
    }
}
